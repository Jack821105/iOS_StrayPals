//
//  ByDistanceSort.swift
//  StrayPals
//
//  【設計模式：策略 Strategy】
//  「離你最近」排序策略。需要使用者位置與「動物 → 收容所座標」的查詢來源，
//  因此以建構參數注入，與其他無狀態策略並存。座標未知者排到最後。
//

import CoreLocation

// MARK: - ByDistanceSort

struct ByDistanceSort: AnimalSortStrategy {

    var title: String { L10n.sortDistance }

    /// 使用者目前位置。
    let userLocation: CLLocation
    /// 由動物取得收容所座標（通常來自 ShelterGeocoder 快取）。
    let coordinateProvider: (Animal) -> CLLocationCoordinate2D?

    // MARK: AnimalSortStrategy

    func sort(_ animals: [Animal]) -> [Animal] {
        animals.sorted { distance(of: $0) < distance(of: $1) }
    }

    // MARK: Distance

    /// 計算某動物所屬收容所與使用者的距離（公尺）；未知座標回傳極大值。
    func distance(of animal: Animal) -> CLLocationDistance {
        guard let coordinate = coordinateProvider(animal) else {
            return .greatestFiniteMagnitude
        }
        let shelter = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return userLocation.distance(from: shelter)
    }
}
