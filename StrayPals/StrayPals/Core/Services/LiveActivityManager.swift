//
//  LiveActivityManager.swift
//  StrayPals (MaoWo)
//
//  【設計模式：單例 Singleton】
//  管理「認養倒數」Live Activity（鎖定畫面 + 動態島）的啟動與結束。
//  使用者主動於詳情頁開啟一個「進行中、有時效」的認養截止倒數事件，
//  符合 Live Activity 的設計用途。所有 API 皆以 #if canImport / #available 包覆，
//  確保在不支援的環境仍可正常編譯與執行。
//

import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - LiveActivityManager

final class LiveActivityManager {

    // MARK: Singleton

    static let shared = LiveActivityManager()
    private init() {}

    // MARK: Availability

    /// 裝置是否支援且使用者允許 Live Activity。
    var isSupported: Bool {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
        #endif
        return false
    }

    // MARK: Start / End

    /// 為指定動物開啟認養倒數，回傳是否成功。
    @discardableResult
    func startCountdown(for animal: Animal) -> Bool {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled,
                  let deadline = animal.closedDateValue else { return false }

            let attributes = AdoptionCountdownAttributes(
                animalName: animal.displayName,
                kindEmoji: Self.emoji(for: animal.kind),
                animalId: animal.id
            )
            let state = AdoptionCountdownAttributes.ContentState(
                deadline: deadline,
                shelterName: animal.shelterName
            )

            do {
                _ = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: deadline),
                    pushType: nil
                )
                return true
            } catch {
                return false
            }
        }
        #endif
        return false
    }

    /// 結束指定動物的倒數活動。
    func endCountdown(animalId: Int) {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            Task {
                for activity in Activity<AdoptionCountdownAttributes>.activities
                where activity.attributes.animalId == animalId {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
        }
        #endif
    }

    /// 指定動物是否已有進行中的倒數活動。
    func isRunning(animalId: Int) -> Bool {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            return Activity<AdoptionCountdownAttributes>.activities
                .contains { $0.attributes.animalId == animalId }
        }
        #endif
        return false
    }

    // MARK: Helpers

    private static func emoji(for kind: AnimalKind) -> String {
        switch kind {
        case .dog:   return "🐶"
        case .cat:   return "🐱"
        case .other: return "🐾"
        }
    }
}
