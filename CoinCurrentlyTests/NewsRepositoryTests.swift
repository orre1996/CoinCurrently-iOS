import Testing
@testable import CoinCurrently

@Suite("NewsRepository Tests")
struct NewsRepositoryTests {

    @Test("getNews returns items on network success")
    func getNewsReturnsData() async {
        let mockNews = NewsModel(data: [NewsItem()])
        let mock = MockRepoNetworkManager(getResult: mockNews)

        let repo = NewsRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getNews(type: NewsType.general, count: 10)
        #expect(result != nil)
        #expect(result?.count == 1)
    }

    @Test("getNews returns nil when network fails")
    func getNewsReturnsNil() async {
        let mock = MockRepoNetworkManager(getResult: nil)

        let repo = NewsRepositoryImp(
            networkManager: mock
        )

        let result = await repo.getNews(type: NewsType.general, count: 10)
        #expect(result == nil)
    }

    @Test("updateNewsType changes selected type")
    func updateNewsType() async {
        let mock = MockRepoNetworkManager()
        let repo = NewsRepositoryImp(
            networkManager: mock
        )

        await repo.updateNewsType(NewsType.neutral)
        #expect(await repo.selectedNewsType == NewsType.neutral)
    }
}
