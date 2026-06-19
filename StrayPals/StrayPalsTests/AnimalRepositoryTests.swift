//
//  AnimalRepositoryTests.swift
//  StrayPalsTests
//
//  測試 Repository 的網路成功、失敗時退回快取（離線 fallback）等行為。
//

import XCTest
@testable import StrayPals

// MARK: - MockAPIClient

private final class MockAPIClient: APIClientProtocol {
    var animalsToReturn: [Animal]?
    var errorToThrow: NetworkError?

    func request<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T {
        if let errorToThrow { throw errorToThrow }
        return (animalsToReturn ?? []) as! T
    }
}

// MARK: - AnimalRepositoryTests

final class AnimalRepositoryTests: XCTestCase {

    private let cacheKey = APIEndpoint.adoptableAnimals.cacheKey

    override func setUp() {
        super.setUp()
        CacheService.shared.remove(forKey: cacheKey)
    }

    override func tearDown() {
        CacheService.shared.remove(forKey: cacheKey)
        super.tearDown()
    }

    func testFetchSuccessReturnsNetworkData() async throws {
        let mock = MockAPIClient()
        mock.animalsToReturn = [AnimalFactory.make(id: 99)]
        let repo = AnimalRepository(apiClient: mock)

        let result = try await repo.fetchAnimals()
        XCTAssertEqual(result.first?.id, 99)
    }

    func testFetchSuccessWritesCache() async throws {
        let mock = MockAPIClient()
        mock.animalsToReturn = [AnimalFactory.make(id: 7)]
        let repo = AnimalRepository(apiClient: mock)

        _ = try await repo.fetchAnimals()
        XCTAssertEqual(repo.cachedAnimals()?.first?.id, 7, "成功後應寫入快取")
    }

    func testFetchFailureFallsBackToCache() async throws {
        // 先放入快取，再讓網路失敗，應沿用快取。
        let mock = MockAPIClient()
        mock.animalsToReturn = [AnimalFactory.make(id: 1)]
        let repo = AnimalRepository(apiClient: mock)
        _ = try await repo.fetchAnimals()   // 寫入快取

        mock.animalsToReturn = nil
        mock.errorToThrow = .transport(URLError(.notConnectedToInternet))

        let result = try await repo.fetchAnimals()
        XCTAssertEqual(result.first?.id, 1, "網路失敗應退回快取")
    }

    func testFetchFailureNoCacheThrows() async {
        let mock = MockAPIClient()
        mock.errorToThrow = .transport(URLError(.timedOut))
        let repo = AnimalRepository(apiClient: mock)

        do {
            _ = try await repo.fetchAnimals()
            XCTFail("無快取時應拋出錯誤")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}
