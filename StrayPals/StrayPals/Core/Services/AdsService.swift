//
//  AdsService.swift
//  StrayPals (MaoWo)
//
//  【設計模式：單例 Singleton】
//  廣告（Google AdMob）的啟動與顯示判斷中樞。是否真的顯示廣告由兩個條件決定：
//    1. 專案是否已加入 GoogleMobileAds 套件（`canImport`）。
//    2. Remote Config 的 `ads_enabled` 是否為開啟（見 AppConfig）。
//
//  以 `#if canImport(GoogleMobileAds)` 閘控，未加入套件時所有方法皆為安全的 no-op。
//

import Foundation
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

// MARK: - AdsService

final class AdsService {

    // MARK: Singleton

    static let shared = AdsService()
    private init() {}

    // MARK: Availability

    /// 是否已整合 AdMob SDK。
    var isSDKAvailable: Bool {
        #if canImport(GoogleMobileAds)
        return true
        #else
        return false
        #endif
    }

    /// 綜合判斷是否應顯示廣告（SDK 存在且遠端開啟）。
    var shouldShowAds: Bool {
        isSDKAvailable && AppConfig.shared.adsEnabled
    }

    // MARK: Lifecycle

    /// 啟動廣告 SDK（在 App 啟動時呼叫）。
    func start() {
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start(completionHandler: nil)
        #endif
    }
}
