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
    /// 預設 session 採用較寬鬆的逾時設定，因開放資料 API 回應較大（數 MB），
    /// 海外 / 慢速網路下載需要更長時間，避免一律 timeout 造成畫面空白。
    private init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30      // 等待「下一段資料」的逾時
            config.timeoutIntervalForResource = 120     // 整包資源下載完成的總逾時
            config.waitsForConnectivity = true          // 暫時沒網路時先等待而非直接失敗
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: config)
        }
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
            (data, response) = try await Self.dataWithRetry(session: session, request: request)
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

    // MARK: - Retry

    /// 帶自動重試的下載：暫時性連線失敗（逾時、連線中斷）時最多重試 2 次（共 3 次嘗試），
    /// 每次間隔遞增，提升海外 / 不穩網路下的成功率。
    private static func dataWithRetry(
        session: URLSession,
        request: URLRequest,
        maxAttempts: Int = 3
    ) async throws -> (Data, URLResponse) {
        var lastError: Error = NetworkError.invalidRequest
        for attempt in 1...maxAttempts {
            do {
                return try await session.data(for: request)
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    // 0.8s、1.6s… 漸進退避（避開任務取消的情況才重試）。
                    try? await Task.sleep(nanoseconds: UInt64(attempt) * 800_000_000)
                }
            }
        }
        throw lastError
    }
}
