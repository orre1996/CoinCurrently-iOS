import Testing
@testable import CoinCurrently

@Suite("FearGreedRepository Tests")
struct FearGreedRepositoryTests {

    @Test("getFearGreed returns data on network success")
    func getFearGreedReturnsData() async {
        let mockFearGreed = FearGreed()
        let mock = MockRepoNetworkManager(getResult: mockFearGreed)

        let repo = FearGreedRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getFearGreed()
        #expect(result != nil)
    }

    @Test("getFearGreed returns nil when network fails")
    func getFearGreedReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = FearGreedRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getFearGreed()
        #expect(result == nil)
    }

    @Test("getFearGreed returns cached data when network fails")
    func getFearGreedReturnsCachedDataOnNetworkFailure() async {
        let cached = FearGreed(data: [FearGreedItem(value: "42", value_classification: "Fear", timestamp: "0", time_until_update: "0")])
        let mock = MockRepoNetworkManager(getResult: cached)

        let repo = FearGreedRepositoryImp(
            networkManager: mock
        )

        _ = await repo.getFearGreed()
        await mock.setGetResult(nil)

        let result = await repo.getFearGreed()
        #expect(result?.data?.first?.value == "42")
    }
}
