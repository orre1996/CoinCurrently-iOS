import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("PortfolioTransactionsViewModel Tests")
struct PortfolioTransactionsViewModelTests {

    @Test("groups a buy into a single day")
    func groupsBuyIntoOneDay() async {
        let viewModel = PortfolioTransactionsViewModel()

        await viewModel.setGroupTransactions(portfolio: [samplePie()])

        #expect(viewModel.groupedTransactions.count == 1)
        #expect(viewModel.groupedTransactions.values.first?.count == 1)
    }

    @Test("type filter drops transactions of other types")
    func typeFilterDropsOtherTypes() async {
        let viewModel = PortfolioTransactionsViewModel()
        viewModel.typeFilters = [.sell]

        await viewModel.setGroupTransactions(portfolio: [samplePie()])

        #expect(viewModel.groupedTransactions.isEmpty)
    }

    @Test("nil portfolio clears the groups")
    func nilPortfolioClearsGroups() async {
        let viewModel = PortfolioTransactionsViewModel()
        await viewModel.setGroupTransactions(portfolio: [samplePie()])

        await viewModel.setGroupTransactions(portfolio: nil)

        #expect(viewModel.groupedTransactions.isEmpty)
    }

    private func samplePie() -> Pie {
        Pie(
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
    }
}
