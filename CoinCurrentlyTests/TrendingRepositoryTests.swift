import Testing
@testable import CoinCurrently

@Suite("TrendingRepository Tests")
struct TrendingRepositoryTests {

    @Test("getTrendingList returns nil when network fails")
    func getTrendingListReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = TrendingRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getTrendingList()
        #expect(result == nil)
    }
}
