//
//  ShelterGroup.swift
//  StrayPals (MaoWo)
//
//  將同一收容所的待認養動物聚合為一筆，供地圖標註與收容所列表使用。
//  座標需透過 ShelterGeocoder 由地址換算（API 不提供經緯度），故為可變並延遲填入。
//

import CoreLocation

// MARK: - ShelterGroup

/// 一間收容所及其名下的待認養動物。
struct ShelterGroup: Hashable {

    let name: String
    let address: String
    let tel: String
    let animals: [Animal]

    /// 由地址地理編碼而得（尚未解析時為 nil）。
    var coordinate: CLLocationCoordinate2D?

    // MARK: Display

    /// 動物數量文字。
    var countText: String { L10n.mapShelterCount(animals.count) }

    /// 是否有任何急需認養的動物。
    var hasUrgent: Bool { animals.contains(where: { $0.isUrgent }) }

    // MARK: Hashable（CLLocationCoordinate2D 不符合 Hashable，需自訂）

    static func == (lhs: ShelterGroup, rhs: ShelterGroup) -> Bool {
        lhs.name == rhs.name && lhs.address == rhs.address && lhs.animals == rhs.animals
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(address)
    }
}
