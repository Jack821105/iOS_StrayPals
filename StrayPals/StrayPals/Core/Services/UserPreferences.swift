//
//  UserPreferences.swift
//  StrayPals (MaoWo)
//
//  【設計模式：單例 Singleton】
//  保存使用者偏好（首次 Onboarding 設定的想養種類、關注縣市），
//  供「為你推薦」個人化排序使用，並記錄是否已完成導覽。
//

import Foundation

// MARK: - UserPreferences

final class UserPreferences {

    // MARK: Singleton

    static let shared = UserPreferences()
    private init() {}

    // MARK: Storage

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let onboarded = "pref_onboarded"
        static let kind = "pref_kind"
        static let cities = "pref_cities"
    }

    // MARK: Onboarding

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.onboarded) }
        set { defaults.set(newValue, forKey: Keys.onboarded) }
    }

    // MARK: Preferences

    /// 偏好的種類（預設全部）。
    var preferredKind: AnimalKindFilter {
        get { AnimalKindFilter(rawValue: defaults.integer(forKey: Keys.kind)) ?? .all }
        set { defaults.set(newValue.rawValue, forKey: Keys.kind) }
    }

    /// 關注的縣市（空＝不限）。
    var preferredCities: Set<String> {
        get { Set(defaults.stringArray(forKey: Keys.cities) ?? []) }
        set { defaults.set(Array(newValue), forKey: Keys.cities) }
    }

    /// 是否有任何個人化偏好可用於推薦。
    var hasAnyPreference: Bool {
        preferredKind != .all || !preferredCities.isEmpty
    }
}
