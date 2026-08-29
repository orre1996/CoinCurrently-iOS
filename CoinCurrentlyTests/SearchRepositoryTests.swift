import Testing
@testable import CoinCurrently

@Suite("SearchRepository Tests")
struct SearchRepositoryTests {

    @Test("getSearchResult returns data on network success")
    func getSearchResultReturnsData() async {
        let mockSearch = SearchModel()
        let mock = MockRepoNetworkManager(getResult: mockSearch)

        let repo = SearchRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getSearchResult(query: "bitcoin")
        #expect(result != nil)
    }

    @Test("getSearchResult returns nil when network fails")
    func getSearchResultReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = SearchRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getSearchResult(query: "nonexistent")
        #expect(result == nil)
    }
}
