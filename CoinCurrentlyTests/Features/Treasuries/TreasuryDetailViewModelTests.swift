import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("TreasuryDetailViewModel Tests")
struct TreasuryDetailViewModelTests {

    @Test("holding chart prices come from the holdings series")
    func holdingChartPrices() async {
        let repo = MockVMTreasuryDetailRepository()
        await repo.setChart(TreasuryHoldingChartModel(
            holdings: [[1, 10], [2, 25]],
            holding_value_in_usd: nil,
            prices: nil,
            market_caps: nil,
            total_volumes: nil
        ))
        let viewModel = makeViewModel(repo: repo)

        await viewModel.getHoldingChart(days: "30")
        viewModel.setPrices()

        #expect(viewModel.getPrices() == [10, 25])
    }

    @Test("getDetail replaces the treasury")
    func getDetailReplacesTreasury() async {
        let repo = MockVMTreasuryDetailRepository()
        await repo.setDetail(sampleEntity(name: "USA"))
        let viewModel = makeViewModel(repo: repo)

        await viewModel.getDetail()

        #expect(viewModel.treasuryDetail?.name == "USA")
    }

    @Test("transaction history follows the repository")
    func transactionHistoryFollowsRepository() async {
        let repo = MockVMTreasuryDetailRepository()
        await repo.setHistory(TreasuryTransactionHistoryModel(transactions: [
            TreasuryTransaction(
                date: 1,
                source_url: nil,
                coin_id: "bitcoin",
                type: .buy,
                holding_net_change: 10,
                transaction_value_usd: 100,
                holding_balance: 10,
                average_entry_value_usd: 10
            )
        ]))
        let viewModel = makeViewModel(repo: repo)

        await viewModel.getTransactionHistory()

        #expect(viewModel.transactionHistory?.transactions?.count == 1)
    }

    private func makeViewModel(repo: MockVMTreasuryDetailRepository) -> TreasuryDetailViewModelImp {
        TreasuryDetailViewModelImp(
            treasuryId: "strategy",
            treasuryDetail: sampleEntity(name: "Strategy"),
            coinId: "bitcoin",
            treasuryDetailRepository: repo,
            cryptoDetailRepository: MockVMCryptoDetailRepository(),
            globalRepository: MockVMGlobalMarketRepository(),
            toplistRepository: MockVMToplistRepository()
        )
    }

    private func sampleEntity(name: String) -> TreasuryDetailEntity {
        TreasuryDetailEntity(
            name: name,
            id: "strategy",
            type: "company",
            symbol: "MSTR",
            country: "US",
            website_url: nil,
            twitter_screen_name: nil,
            total_treasury_value_usd: 1,
            unrealized_pnl: nil,
            m_nav: nil,
            total_asset_value_per_share_usd: nil,
            holdings: nil
        )
    }
}

private extension MockVMTreasuryDetailRepository {
    func setChart(_ chart: TreasuryHoldingChartModel) {
        self.chart = chart
    }

    func setDetail(_ detail: TreasuryDetailEntity) {
        self.detail = detail
    }

    func setHistory(_ history: TreasuryTransactionHistoryModel) {
        self.history = history
    }
}
