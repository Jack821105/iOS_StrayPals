//
//  APIEndpoint.swift
//  StrayPals
//
//  【設計模式：工廠 Factory】
//  以列舉集中描述所有 API 端點，並由 `makeRequest()` 工廠方法
//  統一產生 `URLRequest`。新增端點時只要擴充列舉即可，
//  呼叫端不需要知道 URL 拼接、查詢參數等細節。
//

import Foundation

// MARK: - APIEndpoint

/// 描述後端開放資料平台（農業部）的各個端點。
enum APIEndpoint {

    /// 全國可認養動物清單（流浪動物收容）。
    case adoptableAnimals

    // MARK: Constants

    /// 服務根網域。
    private static let baseURL = "https://data.moa.gov.tw/Service/OpenData/TransService.aspx"

    // MARK: Request Building

    /// 此端點所需的查詢參數。
    private var queryItems: [URLQueryItem] {
        switch self {
        case .adoptableAnimals:
            return [
                URLQueryItem(name: "UnitId", value: "QcbUEzN6E6DL"),
                URLQueryItem(name: "IsTransData", value: "1")
            ]
        }
    }

    /// 組裝後的完整 URL。
    var url: URL? {
        var components = URLComponents(string: Self.baseURL)
        components?.queryItems = queryItems
        return components?.url
    }

    /// 【工廠方法】產生可直接交給 `URLSession` 的請求。
    func makeRequest() -> URLRequest? {
        guard let url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        // 開放資料回應較大（數 MB），海外 / 慢速網路需較長逾時，避免畫面卡在載入。
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    /// 對應的快取鍵，供 `CacheService` 使用。
    var cacheKey: String {
        switch self {
        case .adoptableAnimals:
            return "adoptable_animals"
        }
    }
}
