import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("PortfolioHoldingsViewModel Tests")
struct PortfolioHoldingsViewModelTests {

    @Test("recalculate uses live prices and amounts")
    func recalculateUsesLivePrices() {
        let viewModel = PortfolioHoldingsViewModel()
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

        viewModel.recalculate(
            portfolio: [pie],
            allPrices: [Cryptocurrency(id: "bitcoin", prices: ["usd": 150])],
            pricesById: ["bitcoin": ["usd": 200]],
            amountsById: ["bitcoin": 2],
            currencyCode: "USD",
            profitLossCurrencyCode: "usd"
        )

        #expect(viewModel.totalValue == 400)
        #expect(viewModel.profitLossValue == 50)
        #expect(viewModel.coinFilterList.map(\.id) == ["bitcoin"])
        #expect(viewModel.portfolioPieSlices.isEmpty == false)
    }

    @Test("nil portfolio clears totals and keeps no coin filter")
    func nilPortfolioClearsTotals() {
        let viewModel = PortfolioHoldingsViewModel()

        viewModel.recalculate(
            portfolio: nil,
            allPrices: [],
            pricesById: [:],
            amountsById: [:],
            currencyCode: "USD",
            profitLossCurrencyCode: "usd"
        )

        #expect(viewModel.totalValue == nil)
        #expect(viewModel.profitLossPercent == nil)
        #expect(viewModel.profitLossValue == nil)
        #expect(viewModel.portfolioPieSlices.isEmpty)
        #expect(viewModel.coinFilterList.isEmpty)
    }
}
