import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("NewsViewModel Tests")
struct NewsViewModelTests {

    @Test("setStartData loads the selected cached section")
    func setStartDataLoadsCache() async {
        let repo = MockVMNewsRepository()
        await repo.seed(.general, [NewsItem(title: "Markets", sentiment: "Positive")])
        let viewModel = NewsViewModelImp(
            newsRepository: repo,
            globalMarketRepository: MockVMGlobalMarketRepository(),
            storeKitManager: MockRepoStoreKitManager()
        )

        await viewModel.setStartData()

        #expect(viewModel.news?.first?.title == "Markets")
        #expect(viewModel.selectedNewsType == .general)
    }

    @Test("getNews keeps only the selected sentiment")
    func getNewsFiltersSentiment() async {
        let repo = MockVMNewsRepository()
        await repo.setFetched([
            NewsItem(title: "Up", sentiment: "Positive"),
            NewsItem(title: "Down", sentiment: "Negative")
        ])
        let viewModel = NewsViewModelImp(
            newsRepository: repo,
            globalMarketRepository: MockVMGlobalMarketRepository(),
            storeKitManager: MockRepoStoreKitManager()
        )

        await viewModel.getNews(type: .positive)

        #expect(viewModel.news?.map(\.title) == ["Up"])
        #expect(await repo.updatedType == .positive)
    }

    @Test("hasPro follows the subscription")
    func hasProFollowsSubscription() async {
        let subscribed = NewsViewModelImp(
            newsRepository: MockVMNewsRepository(),
            globalMarketRepository: MockVMGlobalMarketRepository(),
            storeKitManager: MockRepoStoreKitManager(currentSubscription: "pro")
        )
        let free = NewsViewModelImp(
            newsRepository: MockVMNewsRepository(),
            globalMarketRepository: MockVMGlobalMarketRepository(),
            storeKitManager: MockRepoStoreKitManager()
        )

        #expect(await subscribed.hasPro())
        #expect(await free.hasPro() == false)
    }
}

private extension MockVMNewsRepository {
    func seed(_ type: NewsType, _ items: [NewsItem]) {
        cachedNews[type] = CachedData(data: NewsModel(data: items), date: Date())
    }

    func setFetched(_ items: [NewsItem]) {
        news = items
    }
}
