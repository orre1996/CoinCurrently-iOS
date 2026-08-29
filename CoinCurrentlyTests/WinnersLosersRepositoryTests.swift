import Testing
@testable import CoinCurrently

@Suite("WinnersLosersRepository Tests")
struct WinnersLosersRepositoryTests {

    @Test("getWinnersLosersList returns nil when network fails")
    func getWinnersLosersListReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = WinnersLosersRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getWinnersLosersList(priceChange: .oneDay)
        #expect(result == nil)
    }
}
