//
//  ContactUnit.swift
//  StrayPals
//
//  「聯絡單位」（收容所 / 動保機關）的精簡模型，供通報功能選擇對象。
//  由動物資料中的收容所欄位彙整而來。
//

import Foundation

// MARK: - ContactUnit

struct ContactUnit: Hashable {
    let name: String
    let tel: String
    let address: String

    /// 可撥打的電話 URL。
    var phoneURL: URL? {
        let digits = tel.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }
}

// MARK: - 由動物清單彙整聯絡單位

extension Array where Element == Animal {
    /// 取出不重複的聯絡單位（依名稱），並以名稱排序。
    func uniqueContactUnits() -> [ContactUnit] {
        var seen = Set<String>()
        var result: [ContactUnit] = []
        for animal in self where !animal.shelterName.isEmpty {
            guard seen.insert(animal.shelterName).inserted else { continue }
            result.append(ContactUnit(name: animal.shelterName,
                                      tel: animal.shelterTel,
                                      address: animal.shelterAddress))
        }
        return result.sorted { $0.name < $1.name }
    }
}
