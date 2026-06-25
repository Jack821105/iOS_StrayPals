//
//  AnimalRepository.swift
//  StrayPals (MaoWo)
//
//  資料倉儲層：整合「網路」與「快取」兩個來源，對外提供乾淨的 async 介面。
//  ViewModel 只與 Repository 對話，不需知道資料來自 API 還是快取。
//
//  讀取策略（Cache-Then-Network）：
//    1. `cachedAnimals()` 提供有效快取（無則回傳「內建種子資料」），讓畫面「秒開」。
//    2. `fetchAnimals()` 向 API 取得最新；成功則更新快取。
//    3. API 失敗但有快取（即使過期）→ 沿用快取，支援離線瀏覽。
//    4. 連快取都沒有（如全新安裝且首抓失敗）→ 退回「內建種子資料」，
//       確保任何網路狀況下畫面都「不會空白」（審查、海外慢速網路皆然）。
//

import Foundation

// MARK: - AnimalRepositoryProtocol

protocol AnimalRepositoryProtocol {
    /// 立即取得仍有效的快取（無則回傳 nil），供畫面秒開。
    func cachedAnimals() -> [Animal]?

    /// 向 API 取得最新清單；失敗時退回（即使過期的）快取，皆無則拋錯。
    func fetchAnimals() async throws -> [Animal]
}

// MARK: - AnimalRepository

final class AnimalRepository: AnimalRepositoryProtocol {

    // MARK: Dependencies

    private let apiClient: APIClientProtocol
    private let cache: CacheService
    private let analytics: AnalyticsManager
    private let endpoint: APIEndpoint = .adoptableAnimals

    /// 快取有效期限：6 小時。
    private let cacheMaxAge: TimeInterval = 6 * 60 * 60

    // MARK: Init（依賴注入，預設用單例）

    init(
        apiClient: APIClientProtocol = APIClient.shared,
        cache: CacheService = .shared,
        analytics: AnalyticsManager = .shared
    ) {
        self.apiClient = apiClient
        self.cache = cache
        self.analytics = analytics
    }

    // MARK: AnimalRepositoryProtocol

    func cachedAnimals() -> [Animal]? {
        if let cached = cache.load([Animal].self, forKey: endpoint.cacheKey, maxAge: cacheMaxAge),
           !cached.isEmpty {
            analytics.track(.loadedFromCache)
            return cached
        }
        // 無有效快取（如全新安裝）→ 退回內建種子，讓畫面立即有內容、不空白。
        return Self.seedAnimals
    }

    func fetchAnimals() async throws -> [Animal] {
        do {
            let animals = try await apiClient.request(endpoint, as: AnimalListResponse.self)
            cache.save(animals, forKey: endpoint.cacheKey)
            return animals
        } catch {
            // 網路失敗時，若有任何（即使過期的）快取就拿來墊檔。
            if let stale = cache.load([Animal].self,
                                      forKey: endpoint.cacheKey,
                                      maxAge: .greatestFiniteMagnitude),
               !stale.isEmpty {
                return stale
            }
            // 連快取都沒有 → 退回內建種子，確保畫面永遠有內容可顯示。
            if let seed = Self.seedAnimals { return seed }
            throw error
        }
    }

    // MARK: - 內建種子資料（離線 / 海外慢速網路 / 首抓失敗時的最後防線）

    /// 打包在 App 內的動物快照，App 啟動即可立刻顯示，避免任何情況下畫面空白。
    /// 僅解碼一次後常駐記憶體。
    private static let seedAnimals: [Animal]? = {
        guard let url = Bundle.main.url(forResource: "seed_animals", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let animals = try? JSONDecoder().decode([Animal].self, from: data),
              !animals.isEmpty else {
            return nil
        }
        return animals
    }()
}
