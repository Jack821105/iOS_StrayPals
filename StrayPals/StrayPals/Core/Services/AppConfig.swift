//
//  AppConfig.swift
//  StrayPals (MaoWo)
//
//  【設計模式：單例 Singleton】
//  App 遠端設定（Firebase Remote Config）的包裝層，用來「遠端控制」功能開關，
//  最重要的是廣告是否顯示。
//
//  廣告顯示由三層條件決定（見 `resolvedAdsEnabled`）：
//    1. `ads_enabled`：總開關（遠端可關閉所有廣告）。
//    2. 送審安全機制：`disable_ads_for_review` + `review_version`。
//       只有「目前版本 == 送審中版本（最新）」時，才會吃 `disable_ads_for_review`；
//       已上架的舊版本不受影響，照常顯示廣告，避免影響既有營收。
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
        static let disableAdsForReview = "disable_ads_for_review"
        static let reviewVersion = "review_version"
    }

    // MARK: Defaults（未連 Firebase / 尚未抓到雲端值時的後備值）

    private enum Defaults {
        /// 這版先「不顯示廣告」：總開關預設為 false。
        /// 日後要開啟時，到 Firebase Remote Config 後台把 `ads_enabled` 設為 true 即可，
        /// 不需改 App（也可搭配下方 disable_ads_for_review 做送審閘控）。
        static let adsEnabled = false
        /// Google 官方「測試用」橫幅廣告單元 ID；正式上線請改成自己的 AdMob 單元 ID。
        static let adBannerUnitID = "ca-app-pub-3940256099942544/2934735716"
        /// 預設「為送審關閉廣告」= true：最新（送審中）版本在尚未抓到雲端值前先不顯示廣告，
        /// 確保審查員不會看到廣告；上架核准後再於後台把此值設為 false 即可開始顯示。
        static let disableAdsForReview = true
    }

    // MARK: State

    /// 廣告總開關（可由 Remote Config 遠端關閉）。
    private(set) var adsEnabled: Bool = Defaults.adsEnabled
    /// 橫幅廣告單元 ID（可由 Remote Config 遠端調整）。
    private(set) var adBannerUnitID: String = Defaults.adBannerUnitID
    /// 是否為「送審」關閉廣告（僅對最新／送審中版本生效）。
    private(set) var disableAdsForReview: Bool = Defaults.disableAdsForReview
    /// 目前送審中的版本號（marketing version）。預設為本機版本，雲端可覆寫。
    private(set) var reviewVersion: String = AppConfig.currentAppVersion

    // MARK: Derived

    /// 本機 App 版本（CFBundleShortVersionString，例如 "1.0"）。
    static var currentAppVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0"
    }

    /// 目前版本是否為「最新／送審中」版本。
    /// 規則：目前版本 >= `review_version`（數值比較）即視為最新；舊版本則為 false。
    var isLatestVersionUnderReview: Bool {
        let target = reviewVersion.isEmpty ? Self.currentAppVersion : reviewVersion
        // .orderedAscending 代表「目前 < 送審版本」＝舊版；其餘（相等或較新）視為最新。
        return Self.currentAppVersion.compare(target, options: .numeric) != .orderedAscending
    }

    /// 綜合判斷：最終是否要顯示廣告。
    var resolvedAdsEnabled: Bool {
        // 送審安全機制：只有最新（送審中）版本才吃 disable_ads_for_review；舊版照常顯示。
        if isLatestVersionUnderReview && disableAdsForReview { return false }
        return adsEnabled
    }

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
            Keys.adBannerUnitID: Defaults.adBannerUnitID as NSObject,
            Keys.disableAdsForReview: NSNumber(value: Defaults.disableAdsForReview),
            Keys.reviewVersion: Self.currentAppVersion as NSObject
        ])

        remoteConfig.fetchAndActivate { [weak self] _, _ in
            guard let self else { return }
            self.adsEnabled = remoteConfig.configValue(forKey: Keys.adsEnabled).boolValue
            self.disableAdsForReview = remoteConfig.configValue(forKey: Keys.disableAdsForReview).boolValue
            let unit = remoteConfig.configValue(forKey: Keys.adBannerUnitID).stringValue
            if !unit.isEmpty { self.adBannerUnitID = unit }
            let version = remoteConfig.configValue(forKey: Keys.reviewVersion).stringValue
            if !version.isEmpty { self.reviewVersion = version }
            DispatchQueue.main.async { completion?() }
        }
        #else
        // 未整合 Firebase：使用內建預設值。
        completion?()
        #endif
    }
}
