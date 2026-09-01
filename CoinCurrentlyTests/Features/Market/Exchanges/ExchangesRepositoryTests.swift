import Testing
@testable import CoinCurrently

@Suite("ExchangesRepository Tests")
struct ExchangesRepositoryTests {

    @Test("getExchanges returns data on network success")
    func getExchangesReturnsData() async {
        let mockExchanges = [ExchangeModel()]
        let mock = MockRepoNetworkManager(getResult: mockExchanges)

        let repo = ExchangesRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getExchanges()
        #expect(result != nil)
        #expect(result?.count == 1)
    }

    @Test("getExchanges returns nil when network fails")
    func getExchangesReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = ExchangesRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getExchanges()
        #expect(result == nil)
    }
}
