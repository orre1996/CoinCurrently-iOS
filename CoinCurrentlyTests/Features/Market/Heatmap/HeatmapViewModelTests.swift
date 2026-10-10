import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("HeatmapViewModel Tests")
struct HeatmapViewModelTests {

    @Test("loadHeatmapData fills favorites, portfolio, and market lists")
    func loadHeatmapDataFillsLists() async {
        let toplist = MockVMToplistRepository()
        await toplist.setFavorites([Toplist(id: "bitcoin", name: "Bitcoin")])
        await toplist.setMarket([
            Toplist(id: "ethereum", name: "Ethereum", market_cap: 2),
            Toplist(id: "bitcoin", name: "Bitcoin", market_cap: 1)
        ])
        let portfolio = MockVMPortfolioRepository()
        await portfolio.seedPortfolio([
            Pie(
                data: Toplist(id: "solana", name: "Solana", market_cap: 3),
                transactions: [
                    PortfolioTransaction(
                        date: Date(),
                        amount: 1,
                        pricePerCoin: 10,
                        fee: 0,
                        note: "",
                        transactionType: .buy,
                        currency: "usd"
                    )
                ]
            )
        ])
        let viewModel = HeatmapViewModelImp(
            category: CryptoCategory(id: "defi", name: "DeFi"),
            toplistRepository: toplist,
            portfolioRepository: portfolio
        )

        await viewModel.loadHeatmapData()

        #expect(viewModel.favoritesList.map(\.id) == ["bitcoin"])
        #expect(viewModel.portfolioList.map(\.id) == ["solana"])
        #expect(viewModel.toplist.map(\.id) == ["ethereum", "bitcoin"])
        #expect(viewModel.category?.name == "DeFi")
    }
}

private extension MockVMToplistRepository {
    func setFavorites(_ coins: [Toplist]) {
        favorites = coins
    }

    func setMarket(_ coins: [Toplist]) {
        marketToplist = coins
    }
}

private extension MockVMPortfolioRepository {
    func seedPortfolio(_ pies: [Pie]) {
        portfolioResult = CachedPortfolioPies(data: pies, otherCoins: [], date: Date())
    }
}
