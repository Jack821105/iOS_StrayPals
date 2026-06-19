//
//  AppDelegate.swift
//  StrayPals
//
//  App 生命週期進入點。本專案採純程式碼 UI（無 Storyboard），
//  畫面建立交由 SceneDelegate 與 ViewControllerFactory 負責。
//

import UIKit
#if canImport(FirebaseCore)
import FirebaseCore
#endif

// MARK: - AppDelegate

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: App Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // MARK: Firebase（僅在有放入 GoogleService-Info.plist 時才初始化，避免崩潰）
        #if canImport(FirebaseCore)
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        #endif

        // MARK: 遠端設定（廣告 SDK 於取得 ATT 授權後再啟動，見 SceneDelegate）
        AppConfig.shared.refresh()

        AnalyticsManager.shared.track(.appLaunched)
        return true
    }

    // MARK: Scene Configuration

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
