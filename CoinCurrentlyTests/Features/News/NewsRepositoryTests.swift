import Testing
@testable import CoinCurrently

@Suite("NewsRepository Tests")
struct NewsRepositoryTests {

    @Test("getNews returns items on network success")
    func getNewsReturnsData() async {
        let mock = MockRepoNetworkManager(getResult: [NewsItem(title: "Bitcoin rises")])

        let repo = NewsRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getNews(coinId: nil)
        #expect(result?.count == 1)
        #expect(result?.first?.title == "Bitcoin rises")
    }

    @Test("getNews returns nil when network fails")
    func getNewsReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = NewsRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getNews(coinId: "bitcoin")
        #expect(result == nil)
    }
}
