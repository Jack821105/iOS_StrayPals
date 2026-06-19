//
//  HapticsManager.swift
//  StrayPals
//
//  【設計模式：單例 Singleton】
//  集中管理觸覺回饋（Haptic Feedback）。預先產生並 prepare 產生器，
//  降低首次觸發的延遲，讓互動「即時有感」。
//

import UIKit

// MARK: - HapticsManager

final class HapticsManager {

    // MARK: Singleton

    static let shared = HapticsManager()
    private init() {}

    // MARK: Generators

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    // MARK: Public API

    /// 輕量點擊回饋（一般按鈕）。
    func tap() {
        lightImpact.prepare()
        lightImpact.impactOccurred()
    }

    /// 中等回饋（收藏、重要切換）。
    func toggle() {
        mediumImpact.prepare()
        mediumImpact.impactOccurred()
    }

    /// 選取切換回饋（分段控制、選單）。
    func select() {
        selection.prepare()
        selection.selectionChanged()
    }

    /// 成功 / 失敗 / 警告通知回饋。
    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notification.prepare()
        notification.notificationOccurred(type)
    }
}
