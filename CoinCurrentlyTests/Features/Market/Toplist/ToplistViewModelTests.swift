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
            storageManager: emptyStorageManager(),
            analyticsManager: AnalyticsManager.shared
        )

        await viewModel.getToplist(newSortOption: .volumeDesc, newPriceChangeOption: .oneDay)

        #expect(viewModel.toplist.map(\.id) == ["ethereum", "bitcoin"])
        #expect(viewModel.selectedSortOption == .volumeDesc)
        #expect(viewModel.selectedPriceChangeOption == .oneDay)
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
}
