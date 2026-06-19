//
//  PhotoSearchViewModel.swift
//  StrayPals (MaoWo)
//
//  「以圖找毛孩」頁的 ViewModel：載入候選動物，並驅動 ImageSimilarityService
//  進行裝置端相似度比對，以 Observable 廣播查詢圖、進度與結果。
//

import UIKit

// MARK: - PhotoSearchViewModel

final class PhotoSearchViewModel {

    // MARK: Output

    let queryImage = Observable<UIImage?>(nil)
    let matches = Observable<[ImageSimilarityService.Match]>([])
    let isAnalyzing = Observable<Bool>(false)
    let statusText = Observable<String?>(nil)

    var title: String { L10n.photoSearchTitle }

    // MARK: Dependencies

    private let repository: AnimalRepositoryProtocol
    private let similarity = ImageSimilarityService.shared

    // MARK: State

    private var animals: [Animal] = []

    // MARK: Init

    init(repository: AnimalRepositoryProtocol = AnimalRepository()) {
        self.repository = repository
    }

    // MARK: Load

    /// 預先載入候選動物（先用快取，再以網路補齊）。
    func preload() {
        if let cached = repository.cachedAnimals() { animals = cached }
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let fetched = try? await self.repository.fetchAnimals() {
                self.animals = fetched
            }
        }
    }

    // MARK: Analyze

    func analyze(_ image: UIImage) {
        queryImage.value = image
        matches.value = []
        isAnalyzing.value = true
        statusText.value = L10n.photoSearchAnalyzing

        Task { @MainActor [weak self] in
            guard let self else { return }

            // 候選為空時嘗試即時抓取一次。
            if self.animals.isEmpty, let fetched = try? await self.repository.fetchAnimals() {
                self.animals = fetched
            }

            let results = await self.similarity.findSimilar(
                to: image,
                among: self.animals,
                progress: { [weak self] done, total in
                    self?.statusText.value = L10n.photoSearchProgress(done, total)
                }
            )

            self.isAnalyzing.value = false
            // 取前 12 名最相似者呈現。
            self.matches.value = Array(results.prefix(12))
            self.statusText.value = results.isEmpty ? L10n.photoSearchEmpty
                                                    : L10n.photoSearchResult
        }
    }

    // MARK: Helpers

    func similarityText(for match: ImageSimilarityService.Match) -> String {
        L10n.photoSearchSimilarity(match.similarityPercent)
    }
}
