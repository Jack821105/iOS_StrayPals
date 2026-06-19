//
//  CacheService.swift
//  StrayPals
//
//  【設計模式：單例 Singleton】
//  通用的二級快取（記憶體 NSCache + 磁碟 JSON 檔），支援存活時間（TTL）。
//  用於把 API 取得的資料離線保存，達成「無網路時仍可瀏覽」與「秒開」體驗。
//

import Foundation

// MARK: - CacheService

/// 泛用的 Codable 物件快取服務。
final class CacheService {

    // MARK: Singleton

    static let shared = CacheService()

    // MARK: Nested Types

    /// 磁碟上的快取封裝，附帶寫入時間以判斷是否過期。
    private struct Envelope<T: Codable>: Codable {
        let timestamp: Date
        let payload: T
    }

    /// 記憶體快取用的包裝物件（NSCache 需要 class）。
    private final class MemoryBox {
        let timestamp: Date
        let data: Data
        init(timestamp: Date, data: Data) {
            self.timestamp = timestamp
            self.data = data
        }
    }

    // MARK: Properties

    private let memory = NSCache<NSString, MemoryBox>()
    private let fileManager = FileManager.default
    private let directory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    /// 寫入磁碟使用的序列佇列，避免並發讀寫衝突。
    private let ioQueue = DispatchQueue(label: "com.straypals.cache.io")

    // MARK: Init

    private init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = caches.appendingPathComponent("DataCache", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        memory.countLimit = 50
    }

    // MARK: Save

    /// 將物件寫入記憶體與磁碟。
    func save<T: Codable>(_ object: T, forKey key: String) {
        let envelope = Envelope(timestamp: Date(), payload: object)
        guard let data = try? encoder.encode(envelope) else { return }

        memory.setObject(MemoryBox(timestamp: envelope.timestamp, data: data),
                         forKey: key as NSString)

        let url = fileURL(for: key)
        ioQueue.async { [weak self] in
            try? data.write(to: url, options: .atomic)
            _ = self
        }
    }

    // MARK: Load

    /// 讀取尚未過期的快取；超過 `maxAge` 視為失效並回傳 `nil`。
    /// - Parameter maxAge: 可接受的最大存活秒數，預設一天。
    func load<T: Codable>(_ type: T.Type, forKey key: String, maxAge: TimeInterval = 86_400) -> T? {
        // MARK: 先查記憶體
        if let box = memory.object(forKey: key as NSString) {
            return decode(type, from: box.data, timestamp: box.timestamp, maxAge: maxAge)
        }

        // MARK: 再查磁碟
        let url = fileURL(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let envelope = try? decoder.decode(Envelope<T>.self, from: data) else { return nil }
        guard !isExpired(envelope.timestamp, maxAge: maxAge) else { return nil }

        // 回填記憶體
        memory.setObject(MemoryBox(timestamp: envelope.timestamp, data: data),
                         forKey: key as NSString)
        return envelope.payload
    }

    // MARK: Remove

    /// 移除單一鍵的快取。
    func remove(forKey key: String) {
        memory.removeObject(forKey: key as NSString)
        let url = fileURL(for: key)
        ioQueue.async { [weak self] in
            try? self?.fileManager.removeItem(at: url)
        }
    }

    /// 清空所有資料快取。
    func clearAll() {
        memory.removeAllObjects()
        ioQueue.async { [weak self] in
            guard let self else { return }
            try? self.fileManager.removeItem(at: self.directory)
            try? self.fileManager.createDirectory(at: self.directory, withIntermediateDirectories: true)
        }
    }

    // MARK: Helpers

    private func decode<T: Codable>(_ type: T.Type, from data: Data, timestamp: Date, maxAge: TimeInterval) -> T? {
        guard !isExpired(timestamp, maxAge: maxAge) else { return nil }
        return (try? decoder.decode(Envelope<T>.self, from: data))?.payload
    }

    private func isExpired(_ timestamp: Date, maxAge: TimeInterval) -> Bool {
        Date().timeIntervalSince(timestamp) > maxAge
    }

    private func fileURL(for key: String) -> URL {
        // 將鍵做簡單的檔名安全處理。
        let safe = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return directory.appendingPathComponent(safe).appendingPathExtension("json")
    }
}
