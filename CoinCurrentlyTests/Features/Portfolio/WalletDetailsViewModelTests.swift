import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("WalletDetailsViewModel Tests")
struct WalletDetailsViewModelTests {

    @Test("previous price reverses a percent change")
    func previousPriceReversesPercent() async {
        let viewModel = makeViewModel(tokens: [])

        #expect(viewModel.previousPrice(current: 200, percentChange: 100) == 100)
        #expect(viewModel.previousPrice(current: 50, percentChange: -50) == 100)
        #expect(viewModel.previousPrice(current: 10, percentChange: -100) == nil)
    }

    @Test("previous wallet value prices the main balance and tokens")
    func previousWalletValue() async {
        let viewModel = makeViewModel(tokens: [
            TokenInfo(accountHash: "a", balance: "4", tokenHash: "h", tokenSymbol: "USDC", tokenId: "usd-coin")
        ])
        let coins = [
            Toplist(id: "bitcoin", current_price: 200, price_change_percentage_7d_in_currency: 100),
            Toplist(id: "usd-coin", current_price: 1, price_change_percentage_7d_in_currency: 0)
        ]

        let previous = viewModel.calculatePreviousValue(coins: coins, wallet: viewModel.wallet)

        #expect(previous == 204)
    }

    @Test("getCoins sorts tokens by value")
    func getCoinsSortsTokens() async {
        let alerts = MockVMPriceAlertsRepository()
        await alerts.setCoins([
            Toplist(id: "low", current_price: 1),
            Toplist(id: "high", current_price: 10)
        ])
        let viewModel = WalletDetailsViewModelImp(
            portfolioRepository: MockVMPortfolioRepository(),
            priceAlertsRepository: alerts,
            settingsManager: SettingsManager.shared,
            coreDataManager: CoreDataManager.shared,
            wallet: AddressImport(
                coinId: "ethereum",
                address: "0xabc",
                balance: "1",
                tokenInfos: [
                    TokenInfo(accountHash: "a", balance: "5", tokenHash: "l", tokenSymbol: "LOW", tokenId: "low"),
                    TokenInfo(accountHash: "b", balance: "2", tokenHash: "h", tokenSymbol: "HIGH", tokenId: "high")
                ],
                blockChain: .eth
            ),
            coin: Toplist(id: "ethereum", name: "Ethereum")
        )

        await viewModel.getCoins()

        #expect(viewModel.sortedTokens.map(\.tokenId) == ["high", "low"])
        #expect(viewModel.isDoneSorting)
    }

    @Test("rename and delete go through the portfolio repository")
    func renameAndDelete() async {
        let portfolio = MockVMPortfolioRepository()
        let viewModel = WalletDetailsViewModelImp(
            portfolioRepository: portfolio,
            priceAlertsRepository: MockVMPriceAlertsRepository(),
            settingsManager: SettingsManager.shared,
            coreDataManager: CoreDataManager.shared,
            wallet: AddressImport(address: "bc1q", balance: "1", blockChain: .btc),
            coin: Toplist(id: "bitcoin", name: "Bitcoin")
        )

        await viewModel.renameWallet(newName: "Cold storage")
        await viewModel.deleteWallet()

        #expect(viewModel.wallet.walletName == "Cold storage")
        #expect(await portfolio.renamedName == "Cold storage")
        #expect(await portfolio.deleteCount == 1)
    }

    private func makeViewModel(tokens: [TokenInfo]) -> WalletDetailsViewModelImp {
        WalletDetailsViewModelImp(
            portfolioRepository: MockVMPortfolioRepository(),
            priceAlertsRepository: MockVMPriceAlertsRepository(),
            settingsManager: SettingsManager.shared,
            coreDataManager: CoreDataManager.shared,
            wallet: AddressImport(
                coinId: "bitcoin",
                address: "bc1q",
                balance: "2",
                tokenInfos: tokens,
                blockChain: .btc
            ),
            coin: Toplist(id: "bitcoin", name: "Bitcoin")
        )
    }
}

private extension MockVMPriceAlertsRepository {
    func setCoins(_ coins: [Toplist]) {
        remainingCoins = coins
    }
}
