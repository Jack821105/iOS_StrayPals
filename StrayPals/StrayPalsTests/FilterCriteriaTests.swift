//
//  FilterCriteriaTests.swift
//  StrayPalsTests
//
//  測試進階篩選條件 `FilterCriteria.matches` 與狀態判斷。
//

import XCTest
@testable import StrayPals

final class FilterCriteriaTests: XCTestCase {

    func testEmptyCriteriaMatchesEverything() {
        let criteria = FilterCriteria()
        XCTAssertTrue(criteria.matches(AnimalFactory.make(kind: "狗")))
        XCTAssertTrue(criteria.matches(AnimalFactory.make(kind: "貓")))
        XCTAssertFalse(criteria.isActive)
        XCTAssertEqual(criteria.advancedCount, 0)
    }

    func testKindFilter() {
        var criteria = FilterCriteria()
        criteria.kind = .dog
        XCTAssertTrue(criteria.matches(AnimalFactory.make(kind: "狗")))
        XCTAssertFalse(criteria.matches(AnimalFactory.make(kind: "貓")))
        XCTAssertTrue(criteria.isActive)
    }

    func testSexAndAgeFilter() {
        var criteria = FilterCriteria()
        criteria.sexes = ["F"]
        criteria.ages = ["CHILD"]
        XCTAssertTrue(criteria.matches(AnimalFactory.make(sex: "F", age: "CHILD")))
        XCTAssertFalse(criteria.matches(AnimalFactory.make(sex: "M", age: "CHILD")))
        XCTAssertFalse(criteria.matches(AnimalFactory.make(sex: "F", age: "ADULT")))
        XCTAssertEqual(criteria.advancedCount, 2)
    }

    func testSterilizedAndOpenOnly() {
        var criteria = FilterCriteria()
        criteria.sterilizedOnly = true
        criteria.openOnly = true
        XCTAssertTrue(criteria.matches(AnimalFactory.make(sterilization: "T", status: "OPEN")))
        XCTAssertFalse(criteria.matches(AnimalFactory.make(sterilization: "F", status: "OPEN")))
        XCTAssertFalse(criteria.matches(AnimalFactory.make(sterilization: "T", status: "CLOSED")))
    }

    func testCityFilterDerivedFromAddress() {
        var criteria = FilterCriteria()
        criteria.cities = ["臺北市"]
        XCTAssertTrue(criteria.matches(AnimalFactory.make(address: "臺北市內湖區安美街191號")))
        XCTAssertFalse(criteria.matches(AnimalFactory.make(address: "新北市中和區興南路")))
    }
}
