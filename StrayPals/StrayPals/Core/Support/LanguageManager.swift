//
//  LanguageManager.swift
//  StrayPals (MaoWo)
//
//  【設計模式：單例 Singleton】
//  App 內語言切換。使用者可手動選擇語言（不受系統語言限制），並「即時」生效：
//  以選定語系的 .lproj 載入專屬 Bundle，所有 `L10n` 字串都改由此 Bundle 查表，
//  切換後重建畫面即可立刻看到新語言（不需重啟）。
//

import Foundation

// MARK: - AppLanguage

/// 可選語言。
enum AppLanguage: String, CaseIterable {
    case system          // 跟隨系統
    case zhHant = "zh-Hant"
    case zhHans = "zh-Hans"
    case english = "en"

    /// 選單顯示名稱（以該語言本身呈現，較直覺）。
    var displayName: String {
        switch self {
        case .system:  return L10n.languageSystem
        case .zhHant:  return "繁體中文"
        case .zhHans:  return "简体中文"
        case .english: return "English"
        }
    }
}

// MARK: - LanguageManager

final class LanguageManager {

    // MARK: Singleton

    static let shared = LanguageManager()

    /// 語言變更通知（畫面收到後應重建 UI）。
    static let didChangeNotification = Notification.Name("LanguageManager.didChange")

    // MARK: Storage

    private let defaults = UserDefaults.standard
    private let storageKey = "app_language"

    // MARK: State

    /// 目前選定的語言。
    private(set) var language: AppLanguage
    /// 對應語系的 Bundle（字串查表來源）。
    private var bundle: Bundle

    // MARK: Init

    private init() {
        let saved = defaults.string(forKey: storageKey)
        let lang = saved.flatMap(AppLanguage.init(rawValue:)) ?? .system
        self.language = lang
        self.bundle = Self.resolveBundle(for: lang)
    }

    // MARK: Lookup

    /// 查詢在地化字串（供 L10n 使用）。
    func string(_ key: String, _ defaultValue: String) -> String {
        bundle.localizedString(forKey: key, value: defaultValue, table: nil)
    }

    // MARK: Change

    /// 設定語言，更新 Bundle 並發出通知。
    func setLanguage(_ newLanguage: AppLanguage) {
        guard newLanguage != language else { return }
        language = newLanguage
        bundle = Self.resolveBundle(for: newLanguage)

        if newLanguage == .system {
            defaults.removeObject(forKey: storageKey)
            defaults.removeObject(forKey: "AppleLanguages")
        } else {
            defaults.set(newLanguage.rawValue, forKey: storageKey)
            // 同步系統層級偏好，讓系統對話框 / 權限提示也跟隨（下次啟動生效）。
            defaults.set([newLanguage.rawValue], forKey: "AppleLanguages")
        }

        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }

    // MARK: Helpers

    /// 取得指定語言的 .lproj Bundle；找不到則退回主 Bundle（跟隨系統）。
    private static func resolveBundle(for language: AppLanguage) -> Bundle {
        guard language != .system,
              let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let langBundle = Bundle(path: path) else {
            return .main
        }
        return langBundle
    }
}
