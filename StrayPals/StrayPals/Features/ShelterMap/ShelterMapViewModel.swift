//
//  ShelterMapViewModel.swift
//  StrayPals (MaoWo)
//
//  收容所地圖頁的 ViewModel：載入動物資料、依收容所聚合，
//  並透過 ShelterGeocoder 把地址換算為座標（逐筆解析、漸進回報）。
//

import Foundation
import CoreLocation

// MARK: - ShelterMapViewModel

final class ShelterMapViewModel {

    // MARK: Output

    /// 已聚合的收容所（座標可能尚未解析完成）。
    let shelters = Observable<[ShelterGroup]>([])
    let isLoading = Observable<Bool>(false)

    var title: String { L10n.mapTitle }

    // MARK: Dependencies

    private let repository: AnimalRepositoryProtocol
    private let geocoder = ShelterGeocoder.shared

    // MARK: Init

    init(repository: AnimalRepositoryProtocol = AnimalRepository()) {
        self.repository = repository
    }

    // MARK: Load

    func load() {
        if let cached = repository.cachedAnimals() {
            buildGroups(from: cached)
        }
        isLoading.value = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.isLoading.value = false }
            if let animals = try? await self.repository.fetchAnimals() {
                self.buildGroups(from: animals)
            }
        }
    }

    // MARK: Grouping

    private func buildGroups(from animals: [Animal]) {
        var byShelter: [String: [Animal]] = [:]
        for animal in animals where !animal.shelterName.isEmpty {
            let key = animal.shelterName + "|" + animal.shelterAddress
            byShelter[key, default: []].append(animal)
        }

        var groups = byShelter.values.map { list -> ShelterGroup in
            let first = list[0]
            return ShelterGroup(
                name: first.shelterName,
                address: first.shelterAddress,
                tel: first.shelterTel,
                animals: list,
                coordinate: geocoder.cachedCoordinate(for: first.shelterAddress)
            )
        }
        // 動物多者排前，方便地圖優先聚焦熱點。
        groups.sort { $0.animals.count > $1.animals.count }
        shelters.value = groups

        geocodeMissing(groups)
    }

    // MARK: Geocoding

    private func geocodeMissing(_ groups: [ShelterGroup]) {
        let addresses = groups.map(\.address).filter { !$0.isEmpty }
        guard !addresses.isEmpty else { return }
        geocoder.geocodeMissing(
            addresses: addresses,
            onProgress: { [weak self] in self?.refreshCoordinates() },
            completion: { [weak self] in self?.refreshCoordinates() }
        )
    }

    /// 將已解析的座標回填到目前的收容所清單。
    private func refreshCoordinates() {
        var updated = shelters.value
        var didChange = false
        for index in updated.indices where updated[index].coordinate == nil {
            if let coord = geocoder.cachedCoordinate(for: updated[index].address) {
                updated[index].coordinate = coord
                didChange = true
            }
        }
        if didChange { shelters.value = updated }
    }
}
