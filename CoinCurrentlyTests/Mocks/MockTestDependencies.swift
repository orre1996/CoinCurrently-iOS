//
//  MockTestDependencies.swift
//  CoinCurrentlyTests
//
//  Shared mock implementations for repository unit tests.
//

import Testing
import StoreKit
import RevenueCat
import FirebaseRemoteConfig
import FirebaseAuth
@testable import CoinCurrently

// MARK: - Mock Network Manager

actor MockRepoNetworkManager: NetworkManager {
    private var getResult: Any?
    private var getRawResult: (Data, HTTPURLResponse)?
    private var postResult: (Any?, Int)
    private(set) var getCallCount = 0
    private(set) var getRawCallCount = 0
    private(set) var postCallCount = 0

    init(
        getResult: Any? = nil,
        getRawResult: (Data, HTTPURLResponse)? = nil,
        postResult: (Any?, Int) = (nil, 404)
    ) {
        self.getResult = getResult
        self.getRawResult = getRawResult
        self.postResult = postResult
    }

    func setGetResult(_ result: Any?) {
        self.getResult = result
    }

    func setGetRawResult(_ result: (Data, HTTPURLResponse)?) {
        self.getRawResult = result
    }

    func setPostResult(_ result: (Any?, Int)) {
        self.postResult = result
    }

    func setCurrentScreen(_ screen: String) {}

    func get<T: Decodable>(endpoint: Endpoint) async -> T? {
        getCallCount += 1
        return getResult as? T
    }

    func getRaw(endpoint: Endpoint) async -> (data: Data, response: HTTPURLResponse)? {
        getRawCallCount += 1
        return getRawResult
    }

    func getCached<T: Decodable>(endpoint: Endpoint) async -> T? {
        return getResult as? T
    }

    func persistDecodedResponse<T: Encodable>(_ value: T, endpoint: Endpoint) async {}

    func post<G: Codable, T: Codable>(endpoint: Endpoint, bodyStruct: T) async -> (G?, Int) {
        postCallCount += 1
        return (postResult.0 as? G, postResult.1)
    }
}

// MARK: - Mock StoreKit Manager

actor MockRepoStoreKitManager: StoreKitManager {
    var currentSubscription: String?
    var storeProducts: [Product]? { nil }
    var updateListenerTask: Task<Void, Error>? { nil }

    init(currentSubscription: String? = nil) {
        self.currentSubscription = currentSubscription
    }

    func setStartData(downloadSubscriptions: Bool) async {}
    func fetchStoreProducts() async {}
    func requestProducts() async -> [Product]? { nil }
    func streamProducts() -> AsyncStream<[Product]> { AsyncStream { _ in } }
    func isEligableForTrial(using products: [Product]?) async -> Bool { false }
    func purchase(_ product: Product) async -> TransactionState { .failed }
    func listenForTransaction() -> Task<Void, Error> { Task {} }
    func updatePurchasedStatus() async {}
    func restorePurchase() async -> RestorePurchaseResult { .nothingToRestore }
    func getSubscriptionStatus(product: Product?) async -> Bool { false }
    func stream() -> AsyncStream<Bool> { AsyncStream { _ in } }
    func getUser() async {}
    func applyCustomerInfo(_ customerInfo: CustomerInfo?) async {}
}

// MARK: - Mock Firebase Manager

actor MockFirebaseManager: FirebaseManager {
    var alerts = [AlertCoin]()
    var fcmToken: String = ""
    var user: User? = nil

    var configResult: RemoteConfigValue? = nil
    var tokenResult: String? = "mock-token"

    func getConfig(key: RemoteConfigKeys) async -> RemoteConfigValue? { configResult }
    func getConfigBool(key: RemoteConfigKeys) async -> Bool? { configResult?.boolValue }
    func getConfigString(key: RemoteConfigKeys) async -> String? { configResult?.stringValue }
    func getConfigJsonValue<T: Codable>(key: RemoteConfigKeys) async -> T? {
        guard let configValue = configResult?.dataValue else { return nil }
        return try? JSONDecoder().decode(T.self, from: configValue)
    }
    func getUserToken() async -> String? { tokenResult }
    func login() async -> (needsToUpdate: Bool, isBanned: Bool) { (false, false) }
    func sendFeedback(rating: Int, feedback: String) async -> Bool { false }
    func isUserBanned() async -> Bool { false }
    func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult { .orderedSame }
    func compareAppVersion(with version: String?) -> ComparisonResult { .orderedSame }
    func removeUser() async {}
}

// MARK: - Mock Storage Manager

actor MockCachedStorageManager: CachedStorageManager {
    func save<T>(type: Keyable, data: T) where T: Decodable, T: Encodable {}
    func save<T>(type: String, data: T) where T: Decodable, T: Encodable {}
    func load<T>(type: Keyable) -> T? where T: Decodable, T: Encodable { nil }
    func load<T>(type: String) -> T? where T: Decodable, T: Encodable { nil }
    func clear(type: Keyable) -> Bool { true }
    func purge() -> Bool { true }
}

func emptyStorageManager() -> CachedStorageManager {
    MockCachedStorageManager()
}
