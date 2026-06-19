//
//  FilterViewModel.swift
//  StrayPals
//
//  進階篩選頁的 ViewModel。持有一份可編輯的條件「工作副本」，
//  使用者調整時不會立即影響列表，按下「套用」才回傳最終條件。
//

import Foundation

// MARK: - FilterOption

/// 單一可選項目（顯示文字 + 對應代碼）。
struct FilterOption {
    let title: String
    let value: String
}

// MARK: - FilterViewModel

final class FilterViewModel {

    // MARK: Working Copy

    /// 編輯中的條件副本。
    private(set) var criteria: FilterCriteria

    /// 可選縣市（依目前資料動態產生）。
    let cityOptions: [String]

    // MARK: Static Options

    let sexOptions = [FilterOption(title: L10n.sexMale, value: "M"),
                      FilterOption(title: L10n.sexFemale, value: "F")]
    let ageOptions = [FilterOption(title: L10n.ageAdult, value: "ADULT"),
                      FilterOption(title: L10n.ageChild, value: "CHILD")]
    let bodyTypeOptions = [FilterOption(title: L10n.bodySmall, value: "SMALL"),
                           FilterOption(title: L10n.bodyMedium, value: "MEDIUM"),
                           FilterOption(title: L10n.bodyBig, value: "BIG")]

    // MARK: Init

    init(current: FilterCriteria, availableCities: [String]) {
        self.criteria = current
        self.cityOptions = availableCities
    }

    // MARK: Toggling

    func toggleSex(_ value: String) { toggle(\.sexes, value) }
    func toggleAge(_ value: String) { toggle(\.ages, value) }
    func toggleBodyType(_ value: String) { toggle(\.bodyTypes, value) }
    func toggleCity(_ value: String) { toggle(\.cities, value) }

    func setSterilizedOnly(_ on: Bool) { criteria.sterilizedOnly = on }
    func setVaccinatedOnly(_ on: Bool) { criteria.vaccinatedOnly = on }
    func setOpenOnly(_ on: Bool) { criteria.openOnly = on }

    /// 重置為「不限」。
    func reset() {
        let kind = criteria.kind  // 保留種類（由列表分段控制）。
        criteria = FilterCriteria()
        criteria.kind = kind
    }

    // MARK: Query helpers（供 UI 還原選取狀態）

    func isSexSelected(_ v: String) -> Bool { criteria.sexes.contains(v) }
    func isAgeSelected(_ v: String) -> Bool { criteria.ages.contains(v) }
    func isBodyTypeSelected(_ v: String) -> Bool { criteria.bodyTypes.contains(v) }
    func isCitySelected(_ v: String) -> Bool { criteria.cities.contains(v) }

    // MARK: Private

    /// 通用的集合切換工具。
    private func toggle(_ keyPath: WritableKeyPath<FilterCriteria, Set<String>>, _ value: String) {
        if criteria[keyPath: keyPath].contains(value) {
            criteria[keyPath: keyPath].remove(value)
        } else {
            criteria[keyPath: keyPath].insert(value)
        }
    }
}
