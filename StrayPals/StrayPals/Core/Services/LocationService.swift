//
//  LocationService.swift
//  StrayPals
//
//  【設計模式：單例 Singleton】
//  封裝 CoreLocation 的定位權限與「取得目前位置」流程，
//  以單一 completion 回呼結果，隱藏授權狀態的非同步細節。
//

import CoreLocation

// MARK: - LocationService

final class LocationService: NSObject {

    // MARK: Singleton

    static let shared = LocationService()

    // MARK: Error

    enum LocationError: Error {
        case denied        // 使用者拒絕或限制
        case unavailable   // 定位失敗
    }

    // MARK: Properties

    private let manager = CLLocationManager()
    private var pending: ((Result<CLLocation, LocationError>) -> Void)?

    // MARK: Init

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: Public API

    /// 取得目前位置（必要時先請求權限）。
    func requestLocation(completion: @escaping (Result<CLLocation, LocationError>) -> Void) {
        pending = completion
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()   // 後續在 delegate 取得結果
        case .denied, .restricted:
            finish(.failure(.denied))
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        @unknown default:
            finish(.failure(.unavailable))
        }
    }

    // MARK: Helpers

    private func finish(_ result: Result<CLLocation, LocationError>) {
        let callback = pending
        pending = nil
        DispatchQueue.main.async { callback?(result) }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard pending != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            finish(.failure(.denied))
        case .notDetermined:
            break   // 等待使用者選擇
        @unknown default:
            finish(.failure(.unavailable))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            finish(.failure(.unavailable))
            return
        }
        finish(.success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(.failure(.unavailable))
    }
}
