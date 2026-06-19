//
//  AnimalListViewModel.swift
//  StrayPals
//
//  動物列表頁的 ViewModel（MVVM 的 VM 層）。
//  負責：呼叫 Repository 取資料、套用「篩選 + 搜尋 + 排序策略」、
//  以 Observable 將狀態廣播給 ViewController。完全不 import UIKit。
//

import Foundation
import CoreLocation

// MARK: - AnimalKindFilter

/// 種類篩選條件（對應畫面上的分段控制）。
enum AnimalKindFilter: Int, CaseIterable {
    case all = 0
    case dog
    case cat
    case other

    var title: String {
        switch self {
        case .all: return L10n.kindAll
        case .dog: return L10n.kindDog
        case .cat: return L10n.kindCat
        case .other: return L10n.kindOther
        }
    }

    /// 此條件是否符合某動物。
    func matches(_ animal: Animal) -> Bool {
        switch self {
        case .all: return true
        case .dog: return animal.kind == .dog
        case .cat: return animal.kind == .cat
        case .other: return animal.kind == .other   // 非貓狗（兔、鼠、其他）
        }
    }
}

// MARK: - AnimalListViewModel

final class AnimalListViewModel {

    // MARK: Outputs（供 View 綁定）

    /// 經過篩選 / 搜尋 / 排序後，要顯示的清單。
    let animals = Observable<[Animal]>([])
    /// 是否正在載入。
    let isLoading = Observable<Bool>(false)
    /// 錯誤訊息（nil 表示無錯誤）。
    let errorMessage = Observable<String?>(nil)
    /// 是否為「無資料」狀態（用於顯示空狀態視圖）。
    let isEmpty = Observable<Bool>(false)
    /// 目前啟用的進階篩選維度數量（供篩選按鈕徽章顯示）。
    let activeFilterCount = Observable<Int>(0)
    /// 緊急救援（即將截止）動物，僅在無搜尋/篩選時顯示。
    let emergencyAnimals = Observable<[Animal]>([])
    /// 為你推薦（依偏好）動物，僅在無搜尋/篩選時顯示。
    let recommendedAnimals = Observable<[Animal]>([])

    /// 導覽列標題（App 名稱）。
    var title: String { L10n.appName }

    /// 目前是否為「離你最近」排序（避免以在地化字串比較）。
    var isDistanceSortActive: Bool { sortStrategy is ByDistanceSort }

    // MARK: State

    private var allAnimals: [Animal] = []
    private var sortStrategy: AnimalSortStrategy = AnimalSortStrategyProvider.default
    private var criteria = FilterCriteria()
    private var searchText: String = ""
    /// 啟用距離排序時的使用者位置（nil 表示未啟用）。
    private var userLocation: CLLocation?

    // MARK: Dependencies

    private let repository: AnimalRepositoryProtocol
    private let favorites: FavoritesManager
    private let analytics: AnalyticsManager

    // MARK: Init

    init(
        repository: AnimalRepositoryProtocol,
        favorites: FavoritesManager = .shared,
        analytics: AnalyticsManager = .shared
    ) {
        self.repository = repository
        self.favorites = favorites
        self.analytics = analytics
    }

    // MARK: Inputs

    /// 載入清單（Cache-Then-Network）。
    func load(forceReload: Bool = false) {
        // 1) 先以有效快取秒開（非強制重整且尚無資料時）。
        if !forceReload, allAnimals.isEmpty, let cached = repository.cachedAnimals() {
            allAnimals = cached
            analytics.track(.listLoaded(count: cached.count))
            applyTransforms()
        }

        if allAnimals.isEmpty { isLoading.value = true }
        errorMessage.value = nil

        // 2) 再向 API 取得最新。
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let animals = try await self.repository.fetchAnimals()
                self.isLoading.value = false
                self.allAnimals = animals
                self.analytics.track(.listLoaded(count: animals.count))
                self.applyTransforms()
            } catch {
                self.isLoading.value = false
                // 只有在完全沒有資料可顯示時才報錯。
                if self.allAnimals.isEmpty {
                    self.errorMessage.value = (error as? NetworkError)?.localizedDescription
                        ?? error.localizedDescription
                    self.isEmpty.value = true
                }
            }
        }
    }

    /// 切換排序策略（一般無狀態策略）。
    func setSortStrategy(_ strategy: AnimalSortStrategy) {
        userLocation = nil   // 離開距離排序，停止顯示距離
        sortStrategy = strategy
        analytics.track(.changeSort(strategy: strategy.title))
        applyTransforms()
    }

    /// 啟用「離你最近」排序：取得定位 → 套用距離策略 → 背景補齊座標漸進刷新。
    /// - Parameter completion: 是否成功取得定位（false 時 VC 可提示開啟定位權限）。
    func requestNearestSort(completion: @escaping (Bool) -> Void) {
        LocationService.shared.requestLocation { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                completion(false)
            case .success(let location):
                self.userLocation = location
                self.sortStrategy = ByDistanceSort(userLocation: location) { animal in
                    ShelterGeocoder.shared.cachedCoordinate(for: animal.shelterAddress)
                }
                self.analytics.track(.changeSort(strategy: "離你最近"))
                self.applyTransforms()

                // 對尚未編碼的收容所地址做地理編碼，每完成一筆即重新排序。
                ShelterGeocoder.shared.geocodeMissing(
                    addresses: self.allAnimals.map(\.shelterAddress),
                    onProgress: { [weak self] in self?.applyTransforms() },
                    completion: { [weak self] in self?.applyTransforms() }
                )
                completion(true)
            }
        }
    }

    /// 取得某動物的距離顯示文字（僅距離排序啟用且座標已知時）。
    func distanceText(for animal: Animal) -> String? {
        guard let userLocation,
              sortStrategy is ByDistanceSort,
              let coord = ShelterGeocoder.shared.cachedCoordinate(for: animal.shelterAddress) else {
            return nil
        }
        let meters = userLocation.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
        return meters < 1000
            ? L10n.distanceMeters(meters)
            : L10n.distanceKilometers(meters / 1000)
    }

    /// 設定種類篩選（列表頂端分段控制）。
    func setKindFilter(_ filter: AnimalKindFilter) {
        criteria.kind = filter
        analytics.track(.filterKind(kind: filter.title))
        applyTransforms()
    }

    /// 套用進階篩選條件。
    func applyCriteria(_ newCriteria: FilterCriteria) {
        criteria = newCriteria
        analytics.track(.filterKind(kind: "advanced(\(newCriteria.advancedCount))"))
        applyTransforms()
    }

    /// 目前的篩選條件（供進階篩選頁初始化）。
    var currentCriteria: FilterCriteria { criteria }

    /// 依目前資料動態產生可選縣市（排除「其他」並排序）。
    var availableCities: [String] {
        let cities = Set(allAnimals.map(\.city)).subtracting(["其他"])
        return cities.sorted()
    }

    /// 設定搜尋關鍵字。
    func setSearch(_ text: String) {
        searchText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !searchText.isEmpty { analytics.track(.search(keyword: searchText)) }
        applyTransforms()
    }

    // MARK: Favorites

    func isFavorite(_ animal: Animal) -> Bool { favorites.isFavorite(animal) }

    @discardableResult
    func toggleFavorite(_ animal: Animal) -> Bool {
        let isFav = favorites.toggle(animal)
        analytics.track(.toggleFavorite(animalId: animal.id, isFavorite: isFav))
        return isFav
    }

    // MARK: Accessors

    /// 目前的排序策略名稱（顯示用）。
    var currentSortTitle: String { sortStrategy.title }

    /// 取得指定 index 的動物。
    func animal(at index: Int) -> Animal? {
        animals.value.indices.contains(index) ? animals.value[index] : nil
    }

    // MARK: Pipeline（篩選 → 搜尋 → 排序）

    /// 依目前的條件重新計算要顯示的清單。
    private func applyTransforms() {
        var result = allAnimals.filter { criteria.matches($0) }
        activeFilterCount.value = criteria.advancedCount

        if !searchText.isEmpty {
            let keyword = searchText.lowercased()
            result = result.filter { animal in
                animal.shelterName.lowercased().contains(keyword)
                    || animal.variety.lowercased().contains(keyword)
                    || animal.colourText.lowercased().contains(keyword)
                    || animal.foundPlace.lowercased().contains(keyword)
                    || animal.shelterAddress.lowercased().contains(keyword)
            }
        }

        // 【策略模式】套用目前選定的排序演算法。
        result = sortStrategy.sort(result)

        animals.value = result
        isEmpty.value = result.isEmpty && errorMessage.value == nil

        updateHomeSections()
    }

    /// 計算「緊急救援」與「為你推薦」區塊（僅在無搜尋且未啟用進階篩選時顯示）。
    private func updateHomeSections() {
        let isHomeState = searchText.isEmpty && !criteria.isActive
        guard isHomeState else {
            emergencyAnimals.value = []
            recommendedAnimals.value = []
            return
        }

        // 緊急：開放中且即將截止，依剩餘天數遞增。
        let emergency = allAnimals
            .filter { $0.isUrgent }
            .sorted { ($0.daysUntilClosed ?? .max) < ($1.daysUntilClosed ?? .max) }
        emergencyAnimals.value = Array(emergency.prefix(10))

        // 為你推薦：依偏好評分（已在緊急區者不重複）。
        let prefs = UserPreferences.shared
        guard prefs.hasAnyPreference else {
            recommendedAnimals.value = []
            return
        }
        let emergencyIDs = Set(emergencyAnimals.value.map(\.id))
        var scored: [(animal: Animal, score: Int)] = []
        for animal in allAnimals where !emergencyIDs.contains(animal.id) {
            let score = recommendationScore(animal, prefs: prefs)
            if score > 0 { scored.append((animal, score)) }
        }
        scored.sort { lhs, rhs in
            lhs.score == rhs.score ? (lhs.animal.openDate > rhs.animal.openDate) : (lhs.score > rhs.score)
        }
        recommendedAnimals.value = scored.prefix(10).map { $0.animal }
    }

    /// 依使用者偏好計算推薦分數。
    private func recommendationScore(_ animal: Animal, prefs: UserPreferences) -> Int {
        var score = 0
        if prefs.preferredKind != .all, prefs.preferredKind.matches(animal) { score += 3 }
        if prefs.preferredCities.contains(animal.city) { score += 3 }
        if animal.isOpen { score += 1 }
        return score
    }
}
