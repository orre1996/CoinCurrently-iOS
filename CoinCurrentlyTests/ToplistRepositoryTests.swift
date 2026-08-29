import Testing
@testable import CoinCurrently

@Suite("ToplistRepository Tests")
struct ToplistRepositoryTests {

    @Test("getSmallToplist returns nil when network fails")
    func getSmallToplistReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)
        let repo = ToplistRepositoryImp(networkManager: mock)
        let result = await repo.getSmallToplist()
        #expect(result == nil)
    }

    @Test("getCoin returns the downloaded toplist coin")
    func getCoinReturnsDownloadedCoin() async {
        let coin = Toplist(id: "bitcoin", symbol: "btc", name: "Bitcoin")
        let mock = MockRepoNetworkManager(getResult: [coin])
        let repo = ToplistRepositoryImp(networkManager: mock)

        let result = await repo.getCoin(id: "bitcoin")

        #expect(result?.id == "bitcoin")
        #expect(result?.symbol == "btc")
    }

    @Test("getCoin returns nil when network fails")
    func getCoinReturnsNilWhenNetworkFails() async {
        let mock = MockRepoNetworkManager(getResult: nil)
        let repo = ToplistRepositoryImp(networkManager: mock)
        let result = await repo.getCoin(id: "bitcoin")
        #expect(result == nil)
    }
}
