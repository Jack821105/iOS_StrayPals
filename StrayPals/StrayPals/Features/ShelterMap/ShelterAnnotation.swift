//
//  ShelterAnnotation.swift
//  StrayPals (MaoWo)
//
//  地圖上代表一間收容所的標註物件。
//

import MapKit

// MARK: - ShelterAnnotation

final class ShelterAnnotation: NSObject, MKAnnotation {

    let shelter: ShelterGroup
    let coordinate: CLLocationCoordinate2D

    var title: String? { shelter.name }
    var subtitle: String? { shelter.countText }

    init?(shelter: ShelterGroup) {
        guard let coordinate = shelter.coordinate else { return nil }
        self.shelter = shelter
        self.coordinate = coordinate
        super.init()
    }
}
