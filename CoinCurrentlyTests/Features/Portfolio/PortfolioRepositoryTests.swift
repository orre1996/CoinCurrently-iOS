import Testing
@testable import CoinCurrently

@Suite("PortfolioRepository Tests")
struct PortfolioRepositoryTests {

    @Test("getPortfolio returns nil when no portfolio models and network fails")
    func getPortfolioReturnsNilWhenEmpty() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = PortfolioRepositoryImp(
            networkManager: mock,
        )

        let result = await repo.getPortfolio()
        #expect(result == nil)
    }
}
