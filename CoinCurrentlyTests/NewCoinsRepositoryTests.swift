import Testing
@testable import CoinCurrently

@Suite("NewCoinsRepository Tests")
struct NewCoinsRepositoryTests {

    @Test("getNewCoins returns nil when network fails")
    func getNewCoinsReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = NewCoinsRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getNewCoins()
        #expect(result == nil)
    }

    @Test("getActualCoins returns nil for empty ids")
    func getActualCoinsReturnsNilForEmptyIds() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = NewCoinsRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getActualCoins(ids: [])
        #expect(result == nil)
    }
}
