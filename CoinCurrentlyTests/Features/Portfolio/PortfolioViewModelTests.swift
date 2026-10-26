import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("PortfolioViewModel Tests")
struct PortfolioViewModelTests {

    @Test("setStartData loads cached prices and holdings")
    func setStartDataLoadsCache() async {
        let portfolio = MockVMPortfolioRepository()
        let pie = Pie(
            data: Toplist(id: "bitcoin", symbol: "btc", name: "Bitcoin"),
            transactions: [
                PortfolioTransaction(
                    date: Date(timeIntervalSince1970: 1_700_000_000),
                    amount: 1,
                    pricePerCoin: 100,
                    fee: 0,
                    note: "",
                    transactionType: .buy,
                    currency: "usd"
                )
            ]
        )
        await portfolio.seed(
            pies: CachedPortfolioPies(data: [pie], otherCoins: [], date: Date()),
            prices: [Cryptocurrency(id: "bitcoin", prices: ["usd": 150])]
        )
        let viewModel = PortfolioViewModelImp(
            portfolioRepository: portfolio,
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            toplistRepository: MockVMToplistRepository(),
            settingsManager: SettingsManager.shared
        )

        await viewModel.setStartData()

        #expect(viewModel.portfolio?.first?.data?.id == "bitcoin")
        #expect(viewModel.allPrices.first?.id == "bitcoin")
    }

    @Test("findTransaction returns the repository match")
    func findTransactionReturnsMatch() async {
        let portfolio = MockVMPortfolioRepository()
        let event = PortfolioTransaction(
            date: Date(),
            amount: 1,
            pricePerCoin: 1,
            fee: 0,
            note: "",
            transactionType: .buy,
            currency: "usd"
        )
        await portfolio.setFound(event, Toplist(id: "bitcoin", name: "Bitcoin"))
        let viewModel = PortfolioViewModelImp(
            portfolioRepository: portfolio,
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            toplistRepository: MockVMToplistRepository(),
            settingsManager: SettingsManager.shared
        )

        let match = await viewModel.findTransaction(transaction: event.id.uuidString)

        #expect(match.0?.id == event.id)
        #expect(match.1?.id == "bitcoin")
    }

    @Test("clearBenchmark removes the comparison coin")
    func clearBenchmarkRemovesComparison() async {
        let toplist = MockVMToplistRepository()
        await toplist.setCoin(Toplist(id: "bitcoin", name: "Bitcoin"))
        let viewModel = PortfolioViewModelImp(
            portfolioRepository: MockVMPortfolioRepository(),
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            toplistRepository: toplist,
            settingsManager: SettingsManager.shared
        )

        await viewModel.setBenchmarkCoin(id: "bitcoin")
        #expect(viewModel.benchmarkCoin?.id == "bitcoin")

        viewModel.clearBenchmark()

        #expect(viewModel.benchmarkCoin == nil)
    }
}

private extension MockVMToplistRepository {
    func setCoin(_ coin: Toplist) {
        self.coin = coin
    }
}

private extension MockVMPortfolioRepository {
    func seed(pies: CachedPortfolioPies, prices: [Cryptocurrency]) {
        cachedPortfolioPies = pies
        cachedPortfolioPrices = CachedData(data: prices, date: Date())
    }

    func setFound(_ event: any PortfolioEvent, _ coin: Toplist) {
        foundTransaction = (event, coin)
    }
}
