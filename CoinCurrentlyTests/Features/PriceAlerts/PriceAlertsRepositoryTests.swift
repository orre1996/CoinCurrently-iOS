import Testing
@testable import CoinCurrently

@Suite("PriceAlertsRepository Tests")
struct PriceAlertsRepositoryTests {

    @Test("triggerPriceAlert calls post")
    func triggerPriceAlertCallsPost() async {
        let mock = MockRepoNetworkManager(postResult: (nil, 200))

        let repo = PriceAlertsRepositoryImp(
            networkManager: mock,
            storageManager: emptyStorageManager(),
            storeKitManager: MockRepoStoreKitManager(),
            firebaseManager: MockFirebaseManager()
        )

        await repo.triggerPriceAlert()

        let callCount = await mock.postCallCount
        #expect(callCount == 1)
    }

    @Test("triggerBigMover calls post")
    func triggerBigMoverCallsPost() async {
        let mock = MockRepoNetworkManager(postResult: (nil, 200))

        let repo = PriceAlertsRepositoryImp(
            networkManager: mock,
            storageManager: emptyStorageManager(),
            storeKitManager: MockRepoStoreKitManager(),
            firebaseManager: MockFirebaseManager()
        )

        await repo.triggerBigMover()

        let callCount = await mock.postCallCount
        #expect(callCount == 1)
    }

    @Test("getAlertPrices returns nil when network fails")
    func getAlertPricesReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = PriceAlertsRepositoryImp(
            networkManager: mock,
            storageManager: emptyStorageManager(),
            storeKitManager: MockRepoStoreKitManager(),
            firebaseManager: MockFirebaseManager()
        )

        let result = await repo.getAlertPrices(ids: ["bitcoin"])
        #expect(result == nil)
    }

    @Test("downloadRemainingCoins returns nil for empty ids")
    func downloadRemainingCoinsReturnsNilForEmptyIds() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = PriceAlertsRepositoryImp(
            networkManager: mock,
            storageManager: emptyStorageManager(),
            storeKitManager: MockRepoStoreKitManager(),
            firebaseManager: MockFirebaseManager()
        )

        let result = await repo.downloadRemainingCoins(ids: [])
        #expect(result == nil)
    }
}
