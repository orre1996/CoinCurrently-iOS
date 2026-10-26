import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("CryptoDetailPortfolioViewModel Tests")
struct CryptoDetailPortfolioViewModelTests {

    @Test("load selects the pie for the coin and groups its transactions")
    func loadSelectsCoinPie() async {
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
        await portfolio.setPortfolio(CachedPortfolioPies(data: [pie], otherCoins: [], date: Date()))
        let viewModel = CryptoDetailPortfolioViewModel(
            portfolioRepository: portfolio,
            settingsManager: SettingsManager.shared
        )

        await viewModel.load(coinId: "bitcoin")

        #expect(viewModel.pie?.data?.id == "bitcoin")
        #expect(viewModel.groupedTransactions?.isEmpty == false)
    }

    @Test("reset clears the loaded coin")
    func resetClearsCoin() async {
        let viewModel = CryptoDetailPortfolioViewModel(
            portfolioRepository: MockVMPortfolioRepository(),
            settingsManager: SettingsManager.shared
        )

        await viewModel.load(coinId: "bitcoin")
        viewModel.reset()

        #expect(viewModel.pie == nil)
        #expect(viewModel.groupedTransactions == nil)
    }

    @Test("toggleHideData flips the local flag")
    func toggleHideDataFlipsFlag() async {
        let previous: Bool = SettingsManager.shared.get(key: AppSettingKey.hidePortfolioValues) ?? false
        defer { SettingsManager.shared.set(data: previous, key: AppSettingKey.hidePortfolioValues) }

        let viewModel = CryptoDetailPortfolioViewModel(
            portfolioRepository: MockVMPortfolioRepository(),
            settingsManager: SettingsManager.shared
        )
        let starting = viewModel.hidePortfolioData

        viewModel.toggleHideData()

        #expect(viewModel.hidePortfolioData == !starting)
    }
}

private extension MockVMPortfolioRepository {
    func setPortfolio(_ pies: CachedPortfolioPies) {
        portfolioResult = pies
    }
}
