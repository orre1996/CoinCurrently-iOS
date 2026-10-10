import Foundation
import Testing
@testable import CoinCurrently

@Suite("TreasuryDetailRepository Tests")
struct TreasuryDetailRepositoryTests {

    @Test("getTreasuryDetail returns nil without an id")
    func getTreasuryDetailReturnsNilWithoutId() async {
        let repo = TreasuryDetailRepositoryImp(networkManager: MockRepoNetworkManager())

        let result = await repo.getTreasuryDetail(id: nil)

        #expect(result == nil)
    }

    @Test("getTreasuryDetail caches the entity under the requested id")
    func getTreasuryDetailCachesEntity() async {
        let detail = TreasuryDetailEntity(
            name: "Strategy",
            id: nil,
            type: "company",
            symbol: "MSTR.US",
            country: "US",
            website_url: nil,
            twitter_screen_name: nil,
            total_treasury_value_usd: 64_000_000_000,
            unrealized_pnl: nil,
            m_nav: nil,
            total_asset_value_per_share_usd: nil,
            holdings: nil
        )
        let repo = TreasuryDetailRepositoryImp(
            networkManager: MockRepoNetworkManager(getResult: detail)
        )

        let result = await repo.getTreasuryDetail(id: "strategy")

        #expect(result?.id == "strategy")
        #expect(result?.name == "Strategy")
        #expect(await repo.cachedTreasuryDetails["strategy"]?.data.total_treasury_value_usd == 64_000_000_000)
    }

    @Test("getHoldingChart returns nil without an id and caches a chart")
    func getHoldingChartCachesChart() async {
        let chart = TreasuryHoldingChartModel(
            holdings: [[1_700_000_000_000, 100]],
            holding_value_in_usd: [[1_700_000_000_000, 5_000_000]],
            prices: nil,
            market_caps: nil,
            total_volumes: nil
        )
        let network = MockRepoNetworkManager(getResult: chart)
        let repo = TreasuryDetailRepositoryImp(networkManager: network)

        let missing = await repo.getHoldingChart(id: nil, coinId: "bitcoin", days: "30")
        let result = await repo.getHoldingChart(id: "strategy", coinId: "bitcoin", days: "30")

        #expect(missing == nil)
        #expect(result?.holdings?.count == 1)
        #expect(await repo.cachedHoldingCharts["strategy-bitcoin-30"]?.data.holding_value_in_usd?.first?.last == 5_000_000)
        #expect(await network.getCallCount == 1)
    }

    @Test("getTransactionHistory uses all when coin id is missing")
    func getTransactionHistoryCachesAllCoins() async {
        let history = TreasuryTransactionHistoryModel(
            transactions: [
                TreasuryTransaction(
                    date: 1_700_000_000,
                    source_url: nil,
                    coin_id: "bitcoin",
                    type: .buy,
                    holding_net_change: 100,
                    transaction_value_usd: 4_000_000,
                    holding_balance: 800_000,
                    average_entry_value_usd: 40_000
                )
            ]
        )
        let repo = TreasuryDetailRepositoryImp(
            networkManager: MockRepoNetworkManager(getResult: history)
        )

        let result = await repo.getTransactionHistory(id: "strategy", coinId: nil)

        #expect(result?.transactions?.count == 1)
        #expect(await repo.cachedTransactionHistory["strategy-all"]?.data.transactions?.first?.type == .buy)
    }

    @Test("loadCachedDataForTreasury reads each cached endpoint")
    func loadCachedDataReadsCache() async {
        let detail = TreasuryDetailEntity(
            name: "USA",
            id: "usa",
            type: "government",
            symbol: nil,
            country: "US",
            website_url: nil,
            twitter_screen_name: nil,
            total_treasury_value_usd: 70_000_000_000,
            unrealized_pnl: nil,
            m_nav: nil,
            total_asset_value_per_share_usd: nil,
            holdings: nil
        )
        let repo = TreasuryDetailRepositoryImp(
            networkManager: MockRepoNetworkManager(getResult: detail)
        )

        await repo.loadCachedDataForTreasury(id: "usa", coinId: "bitcoin", days: "max")

        #expect(await repo.cachedTreasuryDetails["usa"]?.data.name == "USA")
        #expect(await repo.cachedHoldingCharts["usa-bitcoin-max"] == nil)
    }
}
