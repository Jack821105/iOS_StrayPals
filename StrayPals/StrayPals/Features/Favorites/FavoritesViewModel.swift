//
//  FavoritesViewModel.swift
//  StrayPals
//
//  「我的」頁的 ViewModel，提供兩種模式：收藏 / 最近瀏覽。
//  直接讀取 FavoritesManager 與 RecentlyViewedManager（皆為單例），
//  並在兩者的變動通知時更新輸出。
//

import Foundation

// MARK: - MyListMode

/// 「我的」頁的顯示模式。
enum MyListMode: Int, CaseIterable {
    case favorites = 0
    case recent

    var title: String {
        switch self {
        case .favorites: return L10n.mineModeFavorites
        case .recent: return L10n.mineModeRecent
        }
    }
}

// MARK: - FavoritesViewModel

final class FavoritesViewModel {

    // MARK: Output

    /// 目前模式下要顯示的動物清單。
    let animals = Observable<[Animal]>([])
    /// 是否沒有任何資料。
    let isEmpty = Observable<Bool>(true)

    var title: String { L10n.tabMine }

    // MARK: State

    private(set) var mode: MyListMode = .favorites

    // MARK: Dependencies

    private let favorites: FavoritesManager
    private let recent: RecentlyViewedManager
    private let analytics: AnalyticsManager

    // MARK: Init

    init(
        favorites: FavoritesManager = .shared,
        recent: RecentlyViewedManager = .shared,
        analytics: AnalyticsManager = .shared
    ) {
        self.favorites = favorites
        self.recent = recent
        self.analytics = analytics
        NotificationCenter.default.addObserver(
            self, selector: #selector(reload),
            name: FavoritesManager.didChangeNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(reload),
            name: RecentlyViewedManager.didChangeNotification, object: nil
        )
    }

    // MARK: Inputs

    /// 切換模式並重新載入。
    func setMode(_ newMode: MyListMode) {
        mode = newMode
        reload()
    }

    /// 重新讀取目前模式的清單。
    @objc func reload() {
        let list = (mode == .favorites) ? favorites.favorites : recent.items
        animals.value = list
        isEmpty.value = list.isEmpty
    }

    // MARK: Favorites

    func isFavorite(_ animal: Animal) -> Bool { favorites.isFavorite(animal) }

    func toggleFavorite(_ animal: Animal) {
        let isFav = favorites.toggle(animal)
        analytics.track(.toggleFavorite(animalId: animal.id, isFavorite: isFav))
    }

    func animal(at index: Int) -> Animal? {
        animals.value.indices.contains(index) ? animals.value[index] : nil
    }

    // MARK: Empty State 文案

    var emptyTitle: String {
        mode == .favorites ? L10n.mineEmptyFavTitle : L10n.mineEmptyRecentTitle
    }

    var emptyMessage: String {
        mode == .favorites ? L10n.mineEmptyFavMessage : L10n.mineEmptyRecentMessage
    }

    var emptySymbol: String {
        mode == .favorites ? "heart.text.square" : "clock.arrow.circlepath"
    }
}
