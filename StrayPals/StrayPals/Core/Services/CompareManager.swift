//
//  CompareManager.swift
//  StrayPals (MaoWo)
//
//  【設計模式：單例 Singleton】
//  管理「比較清單」：使用者可從詳情頁加入最多三隻動物，於比較頁並排檢視條件。
//  僅存於記憶體（本次使用情境），變動時發出通知讓相關畫面更新。
//

import Foundation

// MARK: - CompareToggleResult

enum CompareToggleResult {
    case added
    case removed
    case full   // 已達上限，未加入
}

// MARK: - CompareManager

final class CompareManager {

    // MARK: Singleton

    static let shared = CompareManager()
    private init() {}

    /// 比較清單變動通知。
    static let didChangeNotification = Notification.Name("CompareManager.didChange")

    // MARK: Config

    let maxCount = 3

    // MARK: State

    private(set) var items: [Animal] = []

    // MARK: Query

    func contains(_ animal: Animal) -> Bool {
        items.contains { $0.id == animal.id }
    }

    var isEmpty: Bool { items.isEmpty }
    var count: Int { items.count }

    // MARK: Mutations

    /// 切換加入 / 移除；超過上限回傳 `.full`。
    @discardableResult
    func toggle(_ animal: Animal) -> CompareToggleResult {
        if contains(animal) {
            remove(animal)
            return .removed
        }
        guard items.count < maxCount else { return .full }
        items.append(animal)
        post()
        return .added
    }

    func remove(_ animal: Animal) {
        items.removeAll { $0.id == animal.id }
        post()
    }

    func clear() {
        items.removeAll()
        post()
    }

    // MARK: Private

    private func post() {
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }
}
