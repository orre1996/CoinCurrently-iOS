import Testing
@testable import CoinCurrently

@Suite("ExchangeDetailsRepository Tests")
struct ExchangeDetailsRepositoryTests {

    @Test("getExchangeDetails returns nil for nil id")
    func getExchangeDetailsWithNilId() async {
        let mock = MockRepoNetworkManager()

        let repo = ExchangeDetailsRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getExchangeDetails(id: nil)
        #expect(result == nil)
    }

    @Test("getExchangePrices returns nil for nil id")
    func getExchangePricesWithNilId() async {
        let mock = MockRepoNetworkManager()

        let repo = ExchangeDetailsRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getExchangePrices(id: nil, days: "7")
        #expect(result == nil)
    }
}
