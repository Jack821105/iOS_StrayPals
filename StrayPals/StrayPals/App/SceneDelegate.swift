//
//  SceneDelegate.swift
//  StrayPals
//
//  建立主視窗並設定根畫面（透過工廠取得 TabBar）。
//

import UIKit

// MARK: - SceneDelegate

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // MARK: Properties

    var window: UIWindow?

    // MARK: Scene Lifecycle

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        AppAppearance.configure()

        let window = UIWindow(windowScene: windowScene)
        window.tintColor = .appPrimary
        // 【工廠模式】根畫面由 ViewControllerFactory 統一建立。
        window.rootViewController = ViewControllerFactory.makeRootTabBar()
        window.makeKeyAndVisible()
        self.window = window

        playLaunchAnimation(on: window)

        // 監聽語言變更 → 即時重建畫面。
        NotificationCenter.default.addObserver(
            self, selector: #selector(languageDidChange),
            name: LanguageManager.didChangeNotification, object: nil
        )
    }

    // MARK: Language Change

    /// 重新建立根畫面，讓新語言立即套用（含淡入轉場）。
    @objc private func languageDidChange() {
        guard let window else { return }
        AppAppearance.configure()
        let newRoot = ViewControllerFactory.makeRootTabBar()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = newRoot
        }
    }

    // MARK: Launch Animation

    /// 在主畫面之上覆蓋啟動動畫，播放完畢後自動移除。
    private func playLaunchAnimation(on window: UIWindow) {
        let launch = LaunchAnimationView(frame: window.bounds)
        launch.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(launch)
        launch.play { [weak self] in
            // 動畫結束 → 首次啟動先導覽，再請求 ATT、啟動廣告。
            self?.showOnboardingIfNeeded(on: window) {
                TrackingManager.shared.requestIfNeeded {
                    AdsService.shared.start()
                }
            }
        }
    }

    /// 首次啟動顯示 Onboarding；已完成則直接執行後續。
    private func showOnboardingIfNeeded(on window: UIWindow, completion: @escaping () -> Void) {
        guard !UserPreferences.shared.hasCompletedOnboarding else {
            completion()
            return
        }
        let onboarding = OnboardingViewController(onFinish: completion)
        window.rootViewController?.present(onboarding, animated: true)
    }
}
