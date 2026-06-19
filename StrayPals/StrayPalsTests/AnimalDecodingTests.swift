//
//  AnimalDecodingTests.swift
//  StrayPalsTests
//
//  測試 Animal 的容錯解碼與顯示用衍生屬性。
//

import XCTest
@testable import StrayPals

final class AnimalDecodingTests: XCTestCase {

    private let sampleJSON = """
    {
      "animal_id": 447268,
      "animal_subid": "VAAAG115033110",
      "animal_kind": "貓",
      "animal_Variety": "混種貓   ",
      "animal_sex": "M",
      "animal_bodytype": "SMALL",
      "animal_colour": "虎斑色",
      "animal_age": "ADULT",
      "animal_sterilization": "T",
      "animal_bacterin": "F",
      "animal_status": "OPEN",
      "album_file": "https://example.com/cat.png",
      "shelter_name": "臺北市動物之家",
      "shelter_address": "臺北市內湖區安美街191號",
      "shelter_tel": "(02)87913254"
    }
    """.data(using: .utf8)!

    func testDecodeFields() throws {
        let animal = try JSONDecoder().decode(Animal.self, from: sampleJSON)
        XCTAssertEqual(animal.id, 447268)
        XCTAssertEqual(animal.kind, .cat)
        XCTAssertEqual(animal.sexText, L10n.sexMale)
        XCTAssertEqual(animal.ageText, L10n.ageAdult)
        XCTAssertEqual(animal.bodyTypeText, L10n.bodySmall)
        XCTAssertTrue(animal.isSterilized)
        XCTAssertFalse(animal.isVaccinated)
        XCTAssertEqual(animal.variety, "混種貓", "品種應去除多餘空白")
        XCTAssertEqual(animal.imageURL?.absoluteString, "https://example.com/cat.png")
        XCTAssertEqual(animal.city, "臺北市")
    }

    func testToleratesMissingFields() throws {
        let json = #"{"animal_id": 5}"#.data(using: .utf8)!
        let animal = try JSONDecoder().decode(Animal.self, from: json)
        XCTAssertEqual(animal.id, 5)
        XCTAssertEqual(animal.kind, .other)
        XCTAssertEqual(animal.sexText, L10n.unknown)
        XCTAssertNil(animal.imageURL)
        XCTAssertEqual(animal.variety, L10n.notProvided)
    }

    func testDecodeArray() throws {
        let arrayJSON = "[\(String(data: sampleJSON, encoding: .utf8)!)]".data(using: .utf8)!
        let animals = try JSONDecoder().decode([Animal].self, from: arrayJSON)
        XCTAssertEqual(animals.count, 1)
    }
}
