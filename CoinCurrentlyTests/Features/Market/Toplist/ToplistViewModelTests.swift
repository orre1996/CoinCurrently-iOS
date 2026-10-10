import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("ToplistViewModel Tests")
struct ToplistViewModelTests {

    @Test("getToplist stores the market list for the new sort")
    func getToplistStoresMarketList() async {
        let repo = MockVMToplistRepository()
        await repo.setMarket([
            Toplist(id: "ethereum", name: "Ethereum"),
            Toplist(id: "bitcoin", name: "Bitcoin")
        ])
        let viewModel = ToplistViewModelImp(
            toplistRepository: repo,
            trendingRepository: MockVMTrendingRepository(),
            winnersLosersRepository: MockVMWinnersLosersRepository(),
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            storeKitManager: MockRepoStoreKitManager(),
            storageManager: emptyStorageManager(),
            analyticsManager: AnalyticsManager.shared
        )

        await viewModel.getToplist(newSortOption: .volumeDesc, newPriceChangeOption: .oneDay)

        #expect(viewModel.toplist.map(\.id) == ["ethereum", "bitcoin"])
        #expect(viewModel.selectedSortOption == .volumeDesc)
        #expect(viewModel.selectedPriceChangeOption == .oneDay)
    }

    @Test("favourite button stops at two coins without a subscription")
    func favouriteButtonStopsAtFreeLimit() async {
        let repo = MockVMToplistRepository()
        await repo.seedFavorites([
            Toplist(id: "bitcoin", name: "Bitcoin"),
            Toplist(id: "ethereum", name: "Ethereum")
        ])
        await repo.setFavouriteResult([Toplist(id: "should-not-apply", name: "Nope")])
        let viewModel = ToplistViewModelImp(
            toplistRepository: repo,
            trendingRepository: MockVMTrendingRepository(),
            winnersLosersRepository: MockVMWinnersLosersRepository(),
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            storeKitManager: MockRepoStoreKitManager(),
            storageManager: emptyStorageManager(),
            analyticsManager: AnalyticsManager.shared
        )
        await viewModel.setStartData()

        await viewModel.favouriteButtonPressed(toplistItem: Toplist(id: "solana", name: "Solana"))

        #expect(viewModel.favoritesList.count == 2)
        #expect(await repo.favouritePressCount == 0)
    }

    @Test("clearToplist empties the visible list")
    func clearToplistEmptiesList() async {
        let repo = MockVMToplistRepository()
        await repo.setMarket([Toplist(id: "bitcoin", name: "Bitcoin")])
        let viewModel = ToplistViewModelImp(
            toplistRepository: repo,
            trendingRepository: MockVMTrendingRepository(),
            winnersLosersRepository: MockVMWinnersLosersRepository(),
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            storeKitManager: MockRepoStoreKitManager(),
            storageManager: emptyStorageManager(),
            analyticsManager: AnalyticsManager.shared
        )
        await viewModel.getToplist(newSortOption: .mktCapDesc, newPriceChangeOption: .sevenDays)

        viewModel.clearToplist()

        #expect(viewModel.toplist.isEmpty)
    }
}

private extension MockVMToplistRepository {
    func setMarket(_ coins: [Toplist]) {
        marketToplist = coins
    }

    func seedFavorites(_ coins: [Toplist]) {
        cachedFavorites = CachedData(data: coins, date: Date())
    }

    func setFavouriteResult(_ coins: [Toplist]) {
        favouriteResult = coins
    }
}
