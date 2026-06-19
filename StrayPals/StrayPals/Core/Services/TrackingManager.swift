//
//  TrackingManager.swift
//  StrayPals (MaoWo)
//
//  【設計模式：單例 Singleton】
//  App Tracking Transparency（ATT）授權請求。使用個人化廣告（AdMob）前，
//  Apple 要求先取得使用者同意追蹤。請在 UI 出現、App 進入 active 後再請求，
//  系統才會顯示授權對話框。
//

import Foundation
import AppTrackingTransparency

// MARK: - TrackingManager

final class TrackingManager {

    // MARK: Singleton

    static let shared = TrackingManager()
    private init() {}

    // MARK: Request

    /// 若尚未決定則請求追蹤授權；無論結果如何都會回呼（主執行緒）。
    func requestIfNeeded(completion: @escaping () -> Void) {
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .notDetermined:
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async { completion() }
            }
        default:
            completion()
        }
    }

    /// 是否已取得追蹤授權（可用於決定廣告是否個人化）。
    var isAuthorized: Bool {
        ATTrackingManager.trackingAuthorizationStatus == .authorized
    }
}
