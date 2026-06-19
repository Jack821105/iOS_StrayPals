//
//  AnimalSortStrategy.swift
//  StrayPals
//
//  【設計模式：策略 Strategy】
//  把「排序規則」抽象成可互換的演算法物件。ViewModel 持有一個
//  `AnimalSortStrategy`，使用者切換排序方式時只要替換策略實例，
//  不需修改 ViewModel 內部邏輯，符合開放封閉原則。
//

import Foundation

// MARK: - AnimalSortStrategy

/// 動物清單的排序策略介面。
protocol AnimalSortStrategy {
    /// 顯示在選單上的名稱。
    var title: String { get }
    /// 對清單套用排序並回傳新陣列。
    func sort(_ animals: [Animal]) -> [Animal]
}

// MARK: - Concrete Strategies

/// 依開放認養日期，最新在前。
struct LatestOpenDateSort: AnimalSortStrategy {
    var title: String { L10n.sortLatest }
    func sort(_ animals: [Animal]) -> [Animal] {
        animals.sorted { $0.openDate > $1.openDate }
    }
}

/// 依資料更新日期，最新在前。
struct RecentlyUpdatedSort: AnimalSortStrategy {
    var title: String { L10n.sortUpdated }
    func sort(_ animals: [Animal]) -> [Animal] {
        animals.sorted { $0.updateDate > $1.updateDate }
    }
}

/// 依收容所名稱排序（同所聚在一起）。
struct ByShelterSort: AnimalSortStrategy {
    var title: String { L10n.sortShelter }
    func sort(_ animals: [Animal]) -> [Animal] {
        animals.sorted {
            $0.shelterName == $1.shelterName
                ? $0.openDate > $1.openDate
                : $0.shelterName < $1.shelterName
        }
    }
}

/// 依種類排序（狗、貓、其他）。
struct ByKindSort: AnimalSortStrategy {
    var title: String { L10n.sortKind }
    func sort(_ animals: [Animal]) -> [Animal] {
        animals.sorted {
            $0.kindRaw == $1.kindRaw
                ? $0.openDate > $1.openDate
                : $0.kindRaw < $1.kindRaw
        }
    }
}

// MARK: - Registry

/// 提供所有可選策略，供 UI 產生選單。
enum AnimalSortStrategyProvider {
    static let all: [AnimalSortStrategy] = [
        LatestOpenDateSort(),
        RecentlyUpdatedSort(),
        ByShelterSort(),
        ByKindSort()
    ]

    /// 預設策略。
    static var `default`: AnimalSortStrategy { LatestOpenDateSort() }
}
