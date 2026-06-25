//
//  TrackingManager.swift
//  StrayPals (MaoWo)
//
//  【設計模式：單例 Singleton】
//  App 追蹤透明度（App Tracking Transparency, ATT）請求中樞。
//
//  Apple 規定：在進行任何「跨 App / 網站追蹤」（如個人化廣告 AdMob）之前，
//  必須先取得使用者的 ATT 授權。因此啟動廣告 SDK 前，務必先呼叫
//  `requestATTIfNeeded(completion:)`。
//
//  Info.plist 需有 `NSUserTrackingUsageDescription` 字串，否則請求授權會被系統忽略。
//

import Foundation
import AppTrackingTransparency
import AdSupport

// MARK: - TrackingManager

final class TrackingManager {

    // MARK: Singleton

    static let shared = TrackingManager()
    private init() {}

    // MARK: ATT Request

    /// 於需要時請求 ATT 授權，完成（不論同意或拒絕）後執行 `completion`。
    ///
    /// - 延遲 0.5 秒再跳出，避免與啟動動畫 / Onboarding 轉場搶畫面，提升彈窗顯示成功率。
    /// - 不論使用者選擇為何，都會回呼 `completion`，呼叫端可在此再啟動廣告 SDK。
    func requestATTIfNeeded(completion: @escaping () -> Void) {
        guard #available(iOS 14, *) else {
            completion()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            #if DEBUG
            print("🔐 [ATT] 請求前狀態 = \(Self.statusText(ATTrackingManager.trackingAuthorizationStatus))")
            #endif
            ATTrackingManager.requestTrackingAuthorization { status in
                #if DEBUG
                print("🔐 [ATT] 請求後狀態 = \(Self.statusText(status))")
                #endif
                DispatchQueue.main.async { completion() }
            }
        }
    }

    #if DEBUG
    @available(iOS 14, *)
    private static func statusText(_ status: ATTrackingManager.AuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined（未決定，會跳彈窗）"
        case .restricted:    return "restricted（受限，不會跳）"
        case .denied:        return "denied（已拒絕，不會再跳）"
        case .authorized:    return "authorized（已同意，不會再跳）"
        @unknown default:    return "unknown"
        }
    }
    #endif
}
