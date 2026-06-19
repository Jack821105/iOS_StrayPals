//
//  FilterCriteria.swift
//  StrayPals
//
//  進階篩選條件。集中描述使用者可調整的所有篩選維度，並提供
//  `matches(_:)` 判斷單一動物是否符合。空集合代表「不限」。
//

import Foundation

// MARK: - FilterCriteria

struct FilterCriteria: Equatable {

    // MARK: Dimensions

    /// 種類（與列表頂端分段控制共用）。
    var kind: AnimalKindFilter = .all
    /// 性別代碼集合（"M"/"F"），空 = 不限。
    var sexes: Set<String> = []
    /// 年齡代碼集合（"ADULT"/"CHILD"），空 = 不限。
    var ages: Set<String> = []
    /// 體型代碼集合（"SMALL"/"MEDIUM"/"BIG"），空 = 不限。
    var bodyTypes: Set<String> = []
    /// 所在縣市集合，空 = 不限。
    var cities: Set<String> = []
    /// 僅顯示已絕育。
    var sterilizedOnly: Bool = false
    /// 僅顯示已打疫苗。
    var vaccinatedOnly: Bool = false
    /// 僅顯示開放認養中。
    var openOnly: Bool = false

    // MARK: State

    /// 是否有任何非預設條件（用於顯示「篩選中」標記）。
    var isActive: Bool {
        kind != .all || !sexes.isEmpty || !ages.isEmpty || !bodyTypes.isEmpty
            || !cities.isEmpty || sterilizedOnly || vaccinatedOnly || openOnly
    }

    /// 進階維度（不含種類）啟用的數量，供按鈕徽章顯示。
    var advancedCount: Int {
        var n = 0
        if !sexes.isEmpty { n += 1 }
        if !ages.isEmpty { n += 1 }
        if !bodyTypes.isEmpty { n += 1 }
        if !cities.isEmpty { n += 1 }
        if sterilizedOnly { n += 1 }
        if vaccinatedOnly { n += 1 }
        if openOnly { n += 1 }
        return n
    }

    // MARK: Matching

    /// 判斷某動物是否符合目前所有條件。
    func matches(_ animal: Animal) -> Bool {
        guard kind.matches(animal) else { return false }
        if !sexes.isEmpty, !sexes.contains(animal.sexRaw.uppercased()) { return false }
        if !ages.isEmpty, !ages.contains(animal.ageRaw.uppercased()) { return false }
        if !bodyTypes.isEmpty, !bodyTypes.contains(animal.bodyTypeRaw.uppercased()) { return false }
        if !cities.isEmpty, !cities.contains(animal.city) { return false }
        if sterilizedOnly, !animal.isSterilized { return false }
        if vaccinatedOnly, !animal.isVaccinated { return false }
        if openOnly, !animal.isOpen { return false }
        return true
    }
}
