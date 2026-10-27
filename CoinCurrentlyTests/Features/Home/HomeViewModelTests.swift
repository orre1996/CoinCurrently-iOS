import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("HomeViewModel Tests")
struct HomeViewModelTests {

    @Test("getList returns the list for the selected carousel")
    func getListReturnsSelectedCarousel() async {
        let viewModel = makeViewModel()
        viewModel.toplist = [Toplist(id: "bitcoin", name: "Bitcoin")]
        viewModel.favoritesList = [Toplist(id: "ethereum", name: "Ethereum")]
        viewModel.newCoins = [Toplist(id: "new", name: "New")]

        #expect(viewModel.getList(filter: .topCoins)?.map(\.id) == ["bitcoin"])
        #expect(viewModel.getList(filter: .favorites)?.map(\.id) == ["ethereum"])
        #expect(viewModel.getList(filter: .newlyListed)?.map(\.id) == ["new"])
    }

    @Test("getGlobalMarket stores the fetched market")
    func getGlobalMarketStoresMarket() async {
        let market = MockVMGlobalMarketRepository()
        await market.setMarket(GlobalMarketModel(data: nil))
        let viewModel = makeViewModel(market: market)

        await viewModel.getGlobalMarket()

        #expect(viewModel.globalMarket != nil)
    }

    private func makeViewModel(market: MockVMGlobalMarketRepository = MockVMGlobalMarketRepository()) -> HomeViewModelImp {
        HomeViewModelImp(
            toplistRepository: MockVMToplistRepository(),
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            winnersLosersRepository: MockVMWinnersLosersRepository(),
            globalMarketRepository: market,
            trendingRepository: MockVMTrendingRepository(),
            newCoinsRepository: MockVMNewCoinsRepository(),
            fearGreedRepository: MockVMFearGreedRepository(),
            gasFeesRepository: MockVMGasFeesRepository(),
            cachedStorageManager: emptyStorageManager(),
            settingsManager: SettingsManager.shared,
            analyticsManager: AnalyticsManager.shared
        )
    }
}

private extension MockVMGlobalMarketRepository {
    func setMarket(_ market: GlobalMarketModel) {
        self.market = market
    }
}
