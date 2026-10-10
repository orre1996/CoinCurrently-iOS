import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("CryptoDetailNewsViewModel Tests")
struct CryptoDetailNewsViewModelTests {

    @Test("loadCached clears news when the symbol is missing")
    func loadCachedClearsMissingSymbol() async {
        let viewModel = CryptoDetailNewsViewModel(newsRepository: MockVMNewsRepository())
        viewModel.news = [NewsItem(title: "Old")]

        await viewModel.loadCached(symbol: nil)

        #expect(viewModel.news.isEmpty)
    }

    @Test("getNews shows an error when nothing is cached or returned")
    func getNewsShowsErrorWhenEmpty() async {
        let viewModel = CryptoDetailNewsViewModel(newsRepository: MockVMNewsRepository())

        await viewModel.getNews(symbol: "btc")

        #expect(viewModel.news.isEmpty)
        #expect(viewModel.showNewsError)
    }

    @Test("getNews replaces cached articles with the fetched list")
    func getNewsReplacesCache() async {
        let repo = MockVMNewsRepository()
        await repo.seedCoinNews(symbol: "BTC", title: "Cached")
        await repo.setFetched([NewsItem(title: "Fresh")])
        let viewModel = CryptoDetailNewsViewModel(newsRepository: repo)

        await viewModel.getNews(symbol: "btc")

        #expect(viewModel.news.map(\.title) == ["Fresh"])
        #expect(viewModel.showNewsError == false)
    }
}

private extension MockVMNewsRepository {
    func seedCoinNews(symbol: String, title: String) {
        cachedNews[.coin(symbol: symbol)] = CachedData(data: NewsModel(data: [NewsItem(title: title)]), date: Date())
    }

    func setFetched(_ items: [NewsItem]) {
        news = items
    }
}
