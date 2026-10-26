//
//  NetworkManagerTests.swift
//  CoinCurrentlyTests
//
//  Unit tests for NetworkManager protocol and NetworkManagerImp
//
//  Note: Add a Unit Test target in Xcode (File > New > Target > Unit Testing Bundle)
//  and add this file to it. Ensure the test target links to CryptoTracker.
//  Requires Swift 5.9+ for Swift Testing.
//

import Foundation
import Testing
@testable import CoinCurrently

// MARK: - Mock URL Protocol

private final class MockURLProtocol: URLProtocol {
    static nonisolated(unsafe) var mockData: Data?
    static nonisolated(unsafe) var mockResponse: HTTPURLResponse?
    static nonisolated(unsafe) var mockError: Error?
    static nonisolated(unsafe) var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lastRequest = request

        if let error = Self.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        if let response = Self.mockResponse {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        if let data = Self.mockData {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func reset() {
        mockData = nil
        mockResponse = nil
        mockError = nil
        lastRequest = nil
    }
}

// MARK: - Mock Network Manager (Protocol Conformance Test)

private actor MockNetworkManager: NetworkManager {
    var currentScreen: String = "Test"
    private let mockGetResult: Any?
    private let mockPostResult: (Any?, Int)

    init(getResult: Any? = nil, postResult: (Any?, Int) = (nil, 404)) {
        self.mockGetResult = getResult
        self.mockPostResult = postResult
    }

    func setCurrentScreen(_ screen: String) {
        currentScreen = screen
    }

    func get<T: Decodable>(endpoint: Endpoint) async -> T? {
        mockGetResult as? T
    }

    func getRaw(endpoint: Endpoint) async -> (data: Data, response: HTTPURLResponse)? {
        nil
    }

    func getCached<T: Decodable>(endpoint: Endpoint) async -> T? {
        mockGetResult as? T
    }

    func persistDecodedResponse<T: Encodable>(_ value: T, endpoint: Endpoint) async {}

    func post<G: Codable, T: Codable>(endpoint: Endpoint, bodyStruct: T) async -> (G?, Int) {
        (mockPostResult.0 as? G, mockPostResult.1)
    }
}

// MARK: - Test Models

private struct TestDecodable: Codable, Equatable {
    let id: String
    let value: Int
}

private struct TestCodable: Codable {
    let name: String
}

// MARK: - Tests

@Suite("NetworkManager Tests")
struct NetworkManagerTests {

    @Suite("Protocol Conformance")
    struct ProtocolConformance {

        @Test("NetworkManagerImp conforms to protocol")
        func networkManagerConformsToProtocol() {
            func acceptsProtocol(_ manager: any NetworkManager) -> Bool { true }
            let manager = NetworkManagerImp.shared
            #expect(acceptsProtocol(manager))
        }

        @Test("MockNetworkManager returns get result")
        func mockNetworkManagerProtocolConformance() async {
            let mockData = TestDecodable(id: "test", value: 42)
            let mock = MockNetworkManager(getResult: mockData)

            let result: TestDecodable? = await mock.get(endpoint: .global)
            #expect(result == mockData)
        }

        @Test("MockNetworkManager setCurrentScreen updates screen")
        func mockNetworkManagerSetCurrentScreen() async {
            let mock = MockNetworkManager()
            await mock.setCurrentScreen("HomeScreen")
            let screen = await mock.currentScreen
            #expect(screen == "HomeScreen")
        }

        @Test("MockNetworkManager post returns result")
        func mockNetworkManagerPost() async {
            let mock = MockNetworkManager(postResult: (TestDecodable(id: "response", value: 200), 200))
            let (result, statusCode): (TestDecodable?, Int) = await mock.post(
                endpoint: .createPriceAlert,
                bodyStruct: TestCodable(name: "test")
            )
            #expect(statusCode == 200)
            #expect(result?.id == "response")
            #expect(result?.value == 200)
        }
    }

    @Suite("NetworkManager with Mocked URLSession", .serialized)
    struct NetworkManagerWithMockedSession {

        @Test("setCurrentScreen does not crash")
        func setCurrentScreen() async {
            MockURLProtocol.reset()
            defer { MockURLProtocol.reset() }

            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: config)

            let manager = NetworkManagerImp(
                firebaseManager: MockFirebaseManager(),
                session: session
            )

            await manager.setCurrentScreen("TestScreen")
        }

        @Test("get returns decoded data on success")
        func getWithMockedResponse() async {
            MockURLProtocol.reset()
            defer { MockURLProtocol.reset() }

            let jsonData = """
            {"id": "bitcoin", "value": 1}
            """.data(using: .utf8)!

            MockURLProtocol.mockData = jsonData
            MockURLProtocol.mockResponse = HTTPURLResponse(
                url: URL(string: "https://api.coingecko.com/api/v3/global")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )

            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: config)

            let manager = NetworkManagerImp(
                firebaseManager: MockFirebaseManager(),
                session: session
            )

            let result: TestDecodable? = await manager.get(endpoint: .global)

            #expect(result != nil)
            #expect(result?.id == "bitcoin")
            #expect(result?.value == 1)
        }

        @Test("get returns nil on invalid JSON")
        func getReturnsNilOnInvalidResponse() async {
            MockURLProtocol.reset()
            defer { MockURLProtocol.reset() }

            await CoreDataManager.shared.set([String: CachedData<Data>](), forKey: .networkCache)

            MockURLProtocol.mockData = "invalid json".data(using: .utf8)
            MockURLProtocol.mockResponse = HTTPURLResponse(
                url: URL(string: "https://example.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )

            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: config)

            let manager = NetworkManagerImp(
                firebaseManager: MockFirebaseManager(),
                session: session
            )

            let result: TestDecodable? = await manager.get(endpoint: .global)

            #expect(result == nil)
        }

        @Test("get treats public treasury 500 with upstream 404 as empty model")
        func getTreatsPublicTreasuryUpstreamNotFoundAsEmpty() async {
            MockURLProtocol.reset()
            defer { MockURLProtocol.reset() }

            let jsonData = """
            {"detail":"System.Net.Http.HttpRequestException: Response status code does not indicate success: 404 (Not Found)."}
            """.data(using: .utf8)!

            MockURLProtocol.mockData = jsonData
            MockURLProtocol.mockResponse = HTTPURLResponse(
                url: URL(string: "https://api.coincurrently.app/crypto/api/v3/companies/public_treasury/dogecoin")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )

            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: config)

            let manager = NetworkManagerImp(
                firebaseManager: MockFirebaseManager(),
                session: session
            )

            let result: PublicTreasuryModel? = await manager.get(
                endpoint: .publicTreasury(entity: .companies, coinId: "dogecoin")
            )

            #expect(result != nil)
            #expect(result?.holders.isEmpty == true)
        }

        @Test("get still returns nil for public treasury 500 without upstream 404")
        func getReturnsNilForPublicTreasuryServerError() async {
            MockURLProtocol.reset()
            defer { MockURLProtocol.reset() }

            let jsonData = """
            {"detail":"An unexpected error occurred."}
            """.data(using: .utf8)!

            MockURLProtocol.mockData = jsonData
            MockURLProtocol.mockResponse = HTTPURLResponse(
                url: URL(string: "https://api.coincurrently.app/crypto/api/v3/companies/public_treasury/bitcoin")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )

            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: config)

            let manager = NetworkManagerImp(
                firebaseManager: MockFirebaseManager(),
                session: session
            )

            let result: PublicTreasuryModel? = await manager.get(
                endpoint: .publicTreasury(entity: .companies, coinId: "bitcoin")
            )

            #expect(result == nil)
        }

        @Test("get returns nil on HTTP error")
        func getReturnsNilOnHTTPError() async {
            MockURLProtocol.reset()
            defer { MockURLProtocol.reset() }

            await CoreDataManager.shared.set([String: CachedData<Data>](), forKey: .networkCache)

            let jsonData = """
            {"id": "bitcoin", "value": 1}
            """.data(using: .utf8)!

            MockURLProtocol.mockData = jsonData
            MockURLProtocol.mockResponse = HTTPURLResponse(
                url: URL(string: "https://api.coingecko.com/api/v3/global")!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )

            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: config)

            let manager = NetworkManagerImp(
                firebaseManager: MockFirebaseManager(),
                session: session
            )

            let result: TestDecodable? = await manager.get(endpoint: .global)

            #expect(result == nil)
        }

        @Test("post returns decoded data on success")
        func postWithMockedResponse() async {
            MockURLProtocol.reset()
            defer { MockURLProtocol.reset() }

            let jsonData = """
            {"id": "created", "value": 201}
            """.data(using: .utf8)!

            MockURLProtocol.mockData = jsonData
            MockURLProtocol.mockResponse = HTTPURLResponse(
                url: URL(string: "https://example.com/create-alert")!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: nil
            )

            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: config)

            let manager = NetworkManagerImp(
                firebaseManager: MockFirebaseManager(),
                session: session
            )

            let (result, statusCode): (TestDecodable?, Int) = await manager.post(
                endpoint: .createPriceAlert,
                bodyStruct: TestCodable(name: "alert")
            )

            #expect(statusCode == 201)
            #expect(result != nil)
            #expect(result?.id == "created")
            #expect(result?.value == 201)
        }
    }
}
