//
//  RecentlyViewedManager.swift
//  StrayPals
//
//  【設計模式：單例 Singleton】
//  記錄使用者最近瀏覽過的動物（以 UserDefaults 持久化），
//  最新在前、自動去重、上限 30 筆。瀏覽詳情時自動寫入。
//

import Foundation

// MARK: - RecentlyViewedManager

final class RecentlyViewedManager {

    // MARK: Singleton

    static let shared = RecentlyViewedManager()

    // MARK: Notification

    /// 紀錄變動時發出。
    static let didChangeNotification = Notification.Name("RecentlyViewedManager.didChange")

    // MARK: Config

    private let maxCount = 30

    // MARK: Properties

    private let defaults = UserDefaults.standard
    private let storageKey = "recently_viewed_animals"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// 最近瀏覽清單（最新在前）。
    private(set) var items: [Animal] = []

    // MARK: Init

    private init() {
        load()
    }

    // MARK: Public API

    /// 記錄一次瀏覽：移除舊的同筆、插到最前、裁切上限。
    func record(_ animal: Animal) {
        items.removeAll { $0.id == animal.id }
        items.insert(animal, at: 0)
        if items.count > maxCount {
            items = Array(items.prefix(maxCount))
        }
        persist()
    }

    /// 清空紀錄。
    func clear() {
        items.removeAll()
        persist()
    }

    // MARK: Persistence

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? decoder.decode([Animal].self, from: data) else { return }
        items = decoded
    }

    private func persist() {
        if let data = try? encoder.encode(items) {
            defaults.set(data, forKey: storageKey)
        }
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }
}
