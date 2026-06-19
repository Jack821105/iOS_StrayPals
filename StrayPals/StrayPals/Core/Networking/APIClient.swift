//
//  APIClient.swift
//  StrayPals (MaoWo)
//
//  【設計模式：單例 Singleton】
//  全 App 共用一個 `URLSession` 的網路客戶端，採 Swift Concurrency（async/await），
//  以 `APIClientProtocol` 抽象介面方便測試替換為假資料。
//

import Foundation

// MARK: - APIClientProtocol

/// 網路請求的抽象介面（便於依賴注入與測試）。
protocol APIClientProtocol {
    /// 向指定端點請求並解碼為泛型型別。
    func request<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T
}

// MARK: - APIClient

/// 預設的網路客戶端實作。
final class APIClient: APIClientProtocol {

    // MARK: Singleton

    static let shared = APIClient()

    // MARK: Properties

    private let session: URLSession
    private let decoder: JSONDecoder

    // MARK: Init

    /// 私有建構子確保單一實例；測試時可改用 `init(session:)`。
    private init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: APIClientProtocol

    func request<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T {
        guard let request = endpoint.makeRequest() else {
            throw NetworkError.invalidRequest
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            // 連線層級錯誤（無網路、逾時…）。
            throw NetworkError.transport(error)
        }

        // MARK: HTTP 狀態碼檢查
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw NetworkError.server(statusCode: http.statusCode)
        }

        // MARK: 空資料檢查
        guard !data.isEmpty else { throw NetworkError.emptyData }

        // MARK: 解碼
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding(error)
        }
    }
}
