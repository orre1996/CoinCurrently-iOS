import Testing
@testable import CoinCurrently

@Suite("CalculatorRepository Tests")
struct CalculatorRepositoryTests {

    @Test("getCalculatorPrices returns nil for empty ids")
    func getCalculatorPricesReturnsNilForEmptyIds() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = CalculatorRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getCalculatorPrices(ids: [])
        #expect(result == nil)
    }

    @Test("getCalculatorPrices returns nil when network fails")
    func getCalculatorPricesReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = CalculatorRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getCalculatorPrices(ids: ["bitcoin", "ethereum"])
        #expect(result == nil)
    }
}
