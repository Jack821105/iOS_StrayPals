//
//  NetworkError.swift
//  StrayPals
//
//  網路層統一錯誤型別，提供對使用者友善的中文訊息。
//

import Foundation

// MARK: - NetworkError

/// API 請求過程中可能發生的錯誤。
enum NetworkError: Error, LocalizedError {

    /// 無法組成有效的 URL / Request。
    case invalidRequest
    /// 連線層級錯誤（無網路、逾時…），帶上底層錯誤。
    case transport(Error)
    /// HTTP 狀態碼非 2xx。
    case server(statusCode: Int)
    /// 回應內容為空。
    case emptyData
    /// JSON 解碼失敗。
    case decoding(Error)

    // MARK: LocalizedError

    /// 顯示給使用者看的描述。
    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "無法建立請求，請稍後再試。"
        case .transport:
            return "網路連線發生問題，請確認您的網路狀態。"
        case .server(let code):
            return "伺服器回應異常（代碼 \(code)）。"
        case .emptyData:
            return "目前沒有取得任何資料。"
        case .decoding:
            return "資料解析失敗，格式可能已變更。"
        }
    }
}
