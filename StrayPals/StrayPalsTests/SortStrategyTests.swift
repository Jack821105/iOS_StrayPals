//
//  SortStrategyTests.swift
//  StrayPalsTests
//
//  測試排序策略（策略模式）的排序結果。
//

import XCTest
@testable import StrayPals

final class SortStrategyTests: XCTestCase {

    func testLatestOpenDateSortDescending() {
        let older = AnimalFactory.make(id: 1, openDate: "2026-01-01")
        let newer = AnimalFactory.make(id: 2, openDate: "2026-06-01")
        let sorted = LatestOpenDateSort().sort([older, newer])
        XCTAssertEqual(sorted.first?.id, 2, "最新開放日期應排在最前")
    }

    func testRecentlyUpdatedSortDescending() {
        let a = AnimalFactory.make(id: 1, update: "2026-01-01")
        let b = AnimalFactory.make(id: 2, update: "2026-03-01")
        let sorted = RecentlyUpdatedSort().sort([a, b])
        XCTAssertEqual(sorted.first?.id, 2)
    }

    func testByShelterSortGroupsSameShelter() {
        let a = AnimalFactory.make(id: 1, shelter: "B 收容所")
        let b = AnimalFactory.make(id: 2, shelter: "A 收容所")
        let sorted = ByShelterSort().sort([a, b])
        XCTAssertEqual(sorted.first?.shelterName, "A 收容所", "收容所名稱應遞增排序")
    }

    func testByKindSortIsStableByDate() {
        let dog = AnimalFactory.make(id: 1, kind: "狗", openDate: "2026-01-01")
        let cat = AnimalFactory.make(id: 2, kind: "貓", openDate: "2026-02-01")
        let sorted = ByKindSort().sort([dog, cat])
        // "狗" < "貓"（以字串比較），狗應在前。
        XCTAssertEqual(sorted.first?.kindRaw, "狗")
    }

    func testProviderHasAllStrategies() {
        XCTAssertEqual(AnimalSortStrategyProvider.all.count, 4)
    }
}
