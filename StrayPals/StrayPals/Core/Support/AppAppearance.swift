//
//  AppAppearance.swift
//  StrayPals (MaoWo)
//
//  集中設定全域外觀（導覽列、分頁列、強調色），確保 iOS 15+ 在捲動與
//  靜止狀態下的列樣式一致，並套用品牌色。於 App 啟動時呼叫一次。
//

import UIKit

// MARK: - AppAppearance

enum AppAppearance {

    /// 套用全域外觀設定。
    static func configure() {
        configureNavigationBar()
        configureTabBar()
    }

    // MARK: Navigation Bar

    private static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .appBackground
        appearance.shadowColor = .clear
        // 大標題使用品牌色，凸顯個性。
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.appPrimary]

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.tintColor = .appPrimary
    }

    // MARK: Tab Bar

    private static func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .appCard

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .appPrimary
    }
}
