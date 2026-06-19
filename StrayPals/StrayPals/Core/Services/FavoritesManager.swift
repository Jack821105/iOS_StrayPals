//
//  FavoritesManager.swift
//  StrayPals
//
//  【設計模式：單例 Singleton】
//  管理使用者「收藏」的動物，以 UserDefaults 持久化。
//  收藏變動時發出通知，讓任何畫面都能即時同步收藏狀態。
//

import Foundation

// MARK: - FavoritesManager

final class FavoritesManager {

    // MARK: Singleton

    static let shared = FavoritesManager()

    // MARK: Notification

    /// 收藏內容變動時發出。
    static let didChangeNotification = Notification.Name("FavoritesManager.didChange")

    // MARK: Properties

    private let defaults = UserDefaults.standard
    private let storageKey = "favorite_animals"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// 收藏的動物（以新加入在前的順序保存）。
    private(set) var favorites: [Animal] = []

    /// 快速查詢用的 id 集合。
    private var favoriteIds: Set<Int> = []

    // MARK: Init

    private init() {
        load()
    }

    // MARK: Public API

    /// 是否已收藏。
    func isFavorite(_ animal: Animal) -> Bool {
        favoriteIds.contains(animal.id)
    }

    /// 切換收藏狀態，回傳切換後是否為已收藏。
    @discardableResult
    func toggle(_ animal: Animal) -> Bool {
        if isFavorite(animal) {
            remove(animal)
            return false
        } else {
            add(animal)
            return true
        }
    }

    // MARK: Mutations

    private func add(_ animal: Animal) {
        guard !isFavorite(animal) else { return }
        favorites.insert(animal, at: 0)
        favoriteIds.insert(animal.id)
        persist()
    }

    private func remove(_ animal: Animal) {
        favorites.removeAll { $0.id == animal.id }
        favoriteIds.remove(animal.id)
        persist()
    }

    // MARK: Persistence

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? decoder.decode([Animal].self, from: data) else { return }
        favorites = decoded
        favoriteIds = Set(decoded.map(\.id))
    }

    private func persist() {
        if let data = try? encoder.encode(favorites) {
            defaults.set(data, forKey: storageKey)
        }
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }
}
