//
//  AnalyticsManager.swift
//  StrayPals
//
//  【設計模式：單例 Singleton】
//  集中處理事件追蹤。目前以 Console 輸出為實作，
//  之後可在 `track(_:)` 內接上 Firebase Analytics / App Store Connect 等服務，
//  呼叫端完全不需改動。
//

import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

// MARK: - AnalyticsEvent

/// 可追蹤的分析事件。
enum AnalyticsEvent {
    case appLaunched
    case listLoaded(count: Int)
    case loadedFromCache
    case viewDetail(animalId: Int)
    case toggleFavorite(animalId: Int, isFavorite: Bool)
    case changeSort(strategy: String)
    case filterKind(kind: String)
    case search(keyword: String)
    case tapCallShelter(animalId: Int)
    case tapOpenMap(animalId: Int)
    case openReport
    case submitReport(unit: String)

    /// 事件名稱（送往後端時的 key）。
    var name: String {
        switch self {
        case .appLaunched:      return "app_launched"
        case .listLoaded:       return "list_loaded"
        case .loadedFromCache:  return "loaded_from_cache"
        case .viewDetail:       return "view_detail"
        case .toggleFavorite:   return "toggle_favorite"
        case .changeSort:       return "change_sort"
        case .filterKind:       return "filter_kind"
        case .search:           return "search"
        case .tapCallShelter:   return "tap_call_shelter"
        case .tapOpenMap:       return "tap_open_map"
        case .openReport:       return "open_report"
        case .submitReport:     return "submit_report"
        }
    }

    /// 事件附帶參數。
    var parameters: [String: Any] {
        switch self {
        case .appLaunched, .loadedFromCache:
            return [:]
        case .listLoaded(let count):
            return ["count": count]
        case .viewDetail(let id):
            return ["animal_id": id]
        case .toggleFavorite(let id, let isFav):
            return ["animal_id": id, "is_favorite": isFav]
        case .changeSort(let strategy):
            return ["strategy": strategy]
        case .filterKind(let kind):
            return ["kind": kind]
        case .search(let keyword):
            return ["keyword": keyword]
        case .tapCallShelter(let id):
            return ["animal_id": id]
        case .tapOpenMap(let id):
            return ["animal_id": id]
        case .openReport:
            return [:]
        case .submitReport(let unit):
            return ["unit": unit]
        }
    }
}

// MARK: - AnalyticsManager

final class AnalyticsManager {

    // MARK: Singleton

    static let shared = AnalyticsManager()
    private init() {}

    // MARK: Tracking

    /// 記錄一個事件。
    func track(_ event: AnalyticsEvent) {
        #if DEBUG
        let params = event.parameters.isEmpty ? "" : " \(event.parameters)"
        print("📊 [Analytics] \(event.name)\(params)")
        #endif

        // Firebase Analytics（無 IDFA 版本，不觸發 ATT）。未連結 SDK 時自動略過。
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(event.name, parameters: event.parameters)
        #endif
    }
}
