//
//  ImageSimilarityService.swift
//  StrayPals (MaoWo)
//
//  【設計模式：單例 Singleton】
//  「以圖找毛孩」核心：完全在裝置端（離線、零 API 成本、保護隱私）使用 Vision
//  的影像特徵向量（VNGenerateImageFeaturePrint）比對使用者照片與收容所動物照片，
//  以特徵距離排序出最相似的浪浪。適用於尋找走失寵物或「找長相相似的可認養動物」。
//

import UIKit
import Vision

// MARK: - ImageSimilarityService

final class ImageSimilarityService {

    // MARK: Singleton

    static let shared = ImageSimilarityService()
    private init() {}

    // MARK: Match

    /// 一筆比對結果：動物 + 特徵距離（越小越相似）。
    struct Match {
        let animal: Animal
        let distance: Float

        /// 將距離轉為 0–100 的相似度（僅供顯示，非絕對數值）。
        var similarityPercent: Int {
            Int((1 / (1 + distance)) * 100)
        }
    }

    // MARK: Config

    /// 單次最多比對的候選數（控制下載量與耗時）。
    private let maxCandidates = 80
    /// 同時下載/運算的並行上限。
    private let concurrency = 8

    // MARK: Public API

    /// 以查詢圖比對候選動物，回傳由相似到不相似排序的結果。
    /// - Parameters:
    ///   - queryImage: 使用者選擇/拍攝的照片。
    ///   - animals: 候選動物（建議先以種類過濾以提升相關度）。
    ///   - progress: 進度回呼（已處理數, 總數），於主執行緒呼叫。
    func findSimilar(
        to queryImage: UIImage,
        among animals: [Animal],
        progress: @escaping (Int, Int) -> Void
    ) async -> [Match] {

        guard let queryPrint = await featurePrint(for: queryImage) else { return [] }

        let candidates = animals.filter { $0.imageURL != nil }.prefix(maxCandidates)
        let total = candidates.count
        guard total > 0 else { return [] }

        var matches: [Match] = []
        var processed = 0

        // 分批並行，避免一次開太多連線。
        for chunk in Array(candidates).chunked(into: concurrency) {
            let chunkMatches = await withTaskGroup(of: Match?.self) { group -> [Match] in
                for animal in chunk {
                    group.addTask { [weak self] in
                        guard let self,
                              let url = animal.imageURL,
                              let image = await self.downloadImage(url),
                              let print = await self.featurePrint(for: image) else { return nil }
                        var distance = Float.greatestFiniteMagnitude
                        do {
                            try queryPrint.computeDistance(&distance, to: print)
                        } catch {
                            return nil
                        }
                        return Match(animal: animal, distance: distance)
                    }
                }
                var collected: [Match] = []
                for await result in group {
                    if let result { collected.append(result) }
                }
                return collected
            }
            matches.append(contentsOf: chunkMatches)
            processed += chunk.count
            let snapshotProcessed = processed
            await MainActor.run { progress(snapshotProcessed, total) }
        }

        return matches.sorted { $0.distance < $1.distance }
    }

    // MARK: Feature Print

    /// 計算單張圖的特徵向量。
    private func featurePrint(for image: UIImage) async -> VNFeaturePrintObservation? {
        guard let cgImage = image.cgImage else { return nil }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNGenerateImageFeaturePrintRequest()
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
                continuation.resume(returning: request.results?.first as? VNFeaturePrintObservation)
            }
        }
    }

    // MARK: Download

    private func downloadImage(_ url: URL) async -> UIImage? {
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - Array Chunking

private extension Array {
    /// 將陣列切成固定大小的子陣列。
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
