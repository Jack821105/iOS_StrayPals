//
//  AppConfig.swift
//  StrayPals (MaoWo)
//
//  【設計模式：單例 Singleton】
//  App 遠端設定（Firebase Remote Config）的包裝層，用來「遠端控制」功能開關，
//  最重要的是廣告是否顯示（`ads_enabled`）。
//
//  ⚙️ 以 `#if canImport(FirebaseRemoteConfig)` 閘控：
//     - 未加入 Firebase 套件時 → 使用內建預設值，App 仍可正常運作。
//     - 加入 Firebase 套件並放入 GoogleService-Info.plist 後 → 自動改由雲端設定控制。
//

import Foundation
#if canImport(FirebaseRemoteConfig)
import FirebaseRemoteConfig
#endif

// MARK: - AppConfig

final class AppConfig {

    // MARK: Singleton

    static let shared = AppConfig()
    private init() {}

    // MARK: Remote Keys

    private enum Keys {
        static let adsEnabled = "ads_enabled"
        static let adBannerUnitID = "ad_banner_unit_id"
    }

    // MARK: Defaults（未連 Firebase 時的後備值）

    private enum Defaults {
        static let adsEnabled = true
        /// Google 官方「測試用」橫幅廣告單元 ID；正式上線請改成自己的 AdMob 單元 ID。
        static let adBannerUnitID = "ca-app-pub-3940256099942544/2934735716"
    }

    // MARK: State

    /// 是否啟用廣告（可由 Remote Config 遠端關閉）。
    private(set) var adsEnabled: Bool = Defaults.adsEnabled
    /// 橫幅廣告單元 ID（可由 Remote Config 遠端調整）。
    private(set) var adBannerUnitID: String = Defaults.adBannerUnitID

    // MARK: Refresh

    /// 向 Remote Config 取得最新設定（未連 Firebase 時直接回呼）。
    func refresh(completion: (() -> Void)? = nil) {
        #if canImport(FirebaseRemoteConfig)
        let remoteConfig = RemoteConfig.remoteConfig()

        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600   // 正式環境建議 ≥1 小時
        remoteConfig.configSettings = settings

        remoteConfig.setDefaults([
            Keys.adsEnabled: NSNumber(value: Defaults.adsEnabled),
            Keys.adBannerUnitID: Defaults.adBannerUnitID as NSObject
        ])

        remoteConfig.fetchAndActivate { [weak self] _, _ in
            guard let self else { return }
            self.adsEnabled = remoteConfig.configValue(forKey: Keys.adsEnabled).boolValue
            let unit = remoteConfig.configValue(forKey: Keys.adBannerUnitID).stringValue
            if !unit.isEmpty { self.adBannerUnitID = unit }
            DispatchQueue.main.async { completion?() }
        }
        #else
        // 未整合 Firebase：使用內建預設值。
        completion?()
        #endif
    }
}
