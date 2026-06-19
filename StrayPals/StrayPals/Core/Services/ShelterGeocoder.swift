//
//  ShelterGeocoder.swift
//  StrayPals
//
//  【設計模式：單例 Singleton】
//  將收容所地址轉成座標（CLGeocoder），並以磁碟快取結果，
//  避免重複地理編碼（API 不提供經緯度，需自行換算）。
//
//  由於同一批動物常共用少數收容所，僅需對「不重複的地址」編碼。
//  編碼採序列進行並節流，避免觸發 CLGeocoder 的頻率限制。
//

import CoreLocation

// MARK: - ShelterGeocoder

final class ShelterGeocoder {

    // MARK: Singleton

    static let shared = ShelterGeocoder()
    private init() { loadCache() }

    // MARK: Cached Coordinate（可 Codable 持久化）

    private struct Coord: Codable {
        let lat: Double
        let lon: Double
    }

    // MARK: Properties

    private let geocoder = CLGeocoder()
    private let cache = CacheService.shared
    private let cacheKey = "shelter_coordinates"
    private var coordinates: [String: Coord] = [:]   // address -> coord
    private let queue = DispatchQueue(label: "com.straypals.geocoder")

    /// 單次最多編碼的地址數（避免長時間佔用，多餘者下次再補）。
    private let maxPerSession = 40

    // MARK: Public API

    /// 取得已快取的座標（未編碼則回傳 nil）。
    func cachedCoordinate(for address: String) -> CLLocationCoordinate2D? {
        guard let c = coordinates[normalize(address)] else { return nil }
        return CLLocationCoordinate2D(latitude: c.lat, longitude: c.lon)
    }

    /// 對一批地址中尚未快取者進行編碼，全部完成後回呼（主執行緒）。
    /// - Parameter onProgress: 每完成一筆即呼叫，方便畫面漸進刷新。
    func geocodeMissing(
        addresses: [String],
        onProgress: (() -> Void)? = nil,
        completion: @escaping () -> Void
    ) {
        let unique = Array(Set(addresses.map(normalize)))
            .filter { !$0.isEmpty && coordinates[$0] == nil }
            .prefix(maxPerSession)

        guard !unique.isEmpty else {
            DispatchQueue.main.async { completion() }
            return
        }

        // 序列編碼，逐筆完成後回報進度。
        geocodeSequentially(Array(unique), index: 0, onProgress: onProgress, completion: completion)
    }

    // MARK: Sequential Geocoding

    private func geocodeSequentially(
        _ addresses: [String],
        index: Int,
        onProgress: (() -> Void)?,
        completion: @escaping () -> Void
    ) {
        guard index < addresses.count else {
            saveCache()
            DispatchQueue.main.async { completion() }
            return
        }

        let address = addresses[index]
        geocoder.geocodeAddressString(address) { [weak self] placemarks, _ in
            guard let self else { return }
            if let location = placemarks?.first?.location {
                self.coordinates[address] = Coord(lat: location.coordinate.latitude,
                                                  lon: location.coordinate.longitude)
                if let onProgress { DispatchQueue.main.async { onProgress() } }
            }
            // 稍作延遲再處理下一筆，避免觸發頻率限制。
            self.queue.asyncAfter(deadline: .now() + 0.15) {
                self.geocodeSequentially(addresses, index: index + 1,
                                         onProgress: onProgress, completion: completion)
            }
        }
    }

    // MARK: Cache Persistence

    private func loadCache() {
        if let saved = cache.load([String: Coord].self, forKey: cacheKey, maxAge: .greatestFiniteMagnitude) {
            coordinates = saved
        }
    }

    private func saveCache() {
        cache.save(coordinates, forKey: cacheKey)
    }

    // MARK: Helpers

    /// 正規化地址：去除空白，作為快取鍵。
    private func normalize(_ address: String) -> String {
        address.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
