import Testing
@testable import CoinCurrently

@Suite("GlobalMarketRepository Tests")
struct GlobalMarketRepositoryTests {

    @Test("getGlobalMarket returns nil when network fails")
    func getGlobalMarketReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = GlobalMarketRepositoryImp(
            networkManager: mock,
            storeKitManager: MockRepoStoreKitManager()
        )

        let result = await repo.getGlobalMarket()
        #expect(result == nil)
    }

    @Test("getAllCoins returns nil when network fails")
    func getAllCoinsReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = GlobalMarketRepositoryImp(
            networkManager: mock,
            storeKitManager: MockRepoStoreKitManager()
        )

        let result = await repo.getAllCoins()
        #expect(result == nil)
    }
}
