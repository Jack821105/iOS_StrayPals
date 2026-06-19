//
//  AnimalFactory.swift
//  StrayPalsTests
//
//  測試用工廠：以 JSON 解碼建立 Animal（Animal 僅提供容錯解碼器，無記憶體建構子）。
//

import Foundation
@testable import StrayPals

enum AnimalFactory {

    /// 建立一筆測試用動物。
    static func make(
        id: Int = 1,
        kind: String = "貓",
        sex: String = "M",
        age: String = "ADULT",
        body: String = "SMALL",
        sterilization: String = "T",
        bacterin: String = "T",
        status: String = "OPEN",
        openDate: String = "2026-01-01",
        update: String = "2026-01-01",
        shelter: String = "臺北市動物之家",
        address: String = "臺北市內湖區安美街191號"
    ) -> Animal {
        let dict: [String: Any] = [
            "animal_id": id,
            "animal_kind": kind,
            "animal_sex": sex,
            "animal_age": age,
            "animal_bodytype": body,
            "animal_sterilization": sterilization,
            "animal_bacterin": bacterin,
            "animal_status": status,
            "animal_opendate": openDate,
            "animal_update": update,
            "shelter_name": shelter,
            "shelter_address": address
        ]
        let data = try! JSONSerialization.data(withJSONObject: dict)
        return try! JSONDecoder().decode(Animal.self, from: data)
    }
}
