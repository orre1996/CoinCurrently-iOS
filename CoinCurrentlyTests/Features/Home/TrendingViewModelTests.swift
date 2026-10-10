import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("TrendingViewModel Tests")
struct TrendingViewModelTests {

    @Test("setStartData keeps cached coins")
    func setStartDataLoadsCache() async {
        let repo = MockVMTrendingRepository()
        await repo.setCachedList(trendingList(coinName: "Bitcoin"))
        let viewModel = TrendingViewModelImp(trendingRepository: repo)

        await viewModel.setStartData()

        #expect(viewModel.trendingList?.coins?.count == 1)
        #expect(viewModel.getTrendingItems(searchCase: .coins)?.first?.name == "Bitcoin")
    }

    @Test("setStartData ignores an empty coin list")
    func setStartDataIgnoresEmptyCoins() async {
        let repo = MockVMTrendingRepository()
        await repo.setCachedList(TrendingItems(coins: [], nfts: nil, categories: nil))
        let viewModel = TrendingViewModelImp(trendingRepository: repo)

        await viewModel.setStartData()

        #expect(viewModel.trendingList == nil)
    }

    @Test("getTrendingItems maps each search case")
    func getTrendingItemsMapsSearchCases() async {
        let repo = MockVMTrendingRepository()
        await repo.setFetchedList(trendingList(coinName: "Bitcoin"))
        let viewModel = TrendingViewModelImp(trendingRepository: repo)

        await viewModel.getTrendingCoins()

        #expect(viewModel.getTrendingItems(searchCase: .onlyCoins)?.first?.id == "bitcoin")
        #expect(viewModel.getTrendingItems(searchCase: .nfts)?.first?.name == "Punks")
        #expect(viewModel.getTrendingItems(searchCase: .categories)?.first?.name == "DeFi")
        #expect(viewModel.getTrendingItems(searchCase: .exchanges)?.isEmpty == true)
    }

    private func trendingList(coinName: String) -> TrendingItems {
        TrendingItems(
            coins: [
                TrendingCoin(item: CoinItem(
                    id: "bitcoin",
                    coin_id: 1,
                    name: coinName,
                    symbol: "btc",
                    market_cap_rank: 1,
                    thumb: nil,
                    small: nil,
                    large: nil,
                    slug: nil,
                    price_btc: nil,
                    score: 0,
                    data: nil
                ))
            ],
            nfts: [
                TrendingNFT(
                    id: "punks",
                    name: "Punks",
                    symbol: "PUNK",
                    thumb: nil,
                    nft_contract_id: nil,
                    native_currency_symbol: nil,
                    floor_price_in_native_currency: nil,
                    floor_price_24h_percentage_change: nil,
                    data: nil
                )
            ],
            categories: [
                TrendingCategory(id: 1, name: "DeFi", market_cap_1h_change: nil, slug: "defi", coins_count: "10", data: nil)
            ]
        )
    }
}

private extension MockVMTrendingRepository {
    func setCachedList(_ list: TrendingItems) {
        cachedTrending = CachedData(data: list, date: Date())
    }

    func setFetchedList(_ list: TrendingItems) {
        trendingList = list
    }
}
