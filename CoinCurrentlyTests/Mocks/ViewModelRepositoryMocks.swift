//
//  ViewModelRepositoryMocks.swift
//  CoinCurrentlyTests
//
//  Configurable repository doubles for view model unit tests.
//

import Foundation
import Combine
import UIKit
@testable import CoinCurrently

func testDecode<T: Decodable>(_ json: String) -> T {
    do {
        return try JSONDecoder().decode(T.self, from: Data(json.utf8))
    } catch {
        fatalError("Test fixture failed to decode \(T.self): \(error)")
    }
}

func sampleCurrency(
    id: String = "bitcoin",
    symbol: String = "btc",
    name: String = "Bitcoin",
    price: Double = 50_000
) -> CurrencyDataModel {
    testDecode(
        """
        {"id":"\(id)","symbol":"\(symbol)","name":"\(name)","market_data":{"current_price":{"usd":\(price),"USD":\(price)}}}
        """
    )
}

func sampleBitcoinRepository(price: Double = 50_000) -> CryptoDetailRepositoryImp {
    CryptoDetailRepositoryImp(
        networkManager: MockRepoNetworkManager(getResult: sampleCurrency(price: price)),
        storageManager: emptyStorageManager(),
        firebaseManager: MockFirebaseManager()
    )
}

actor MockVMToplistRepository: ToplistRepository {
    var cachedFavorites: CachedData<[Toplist]>?
    var cachedSmallToplist: CachedData<[Toplist]>?
    var cachedToplist: [String: CachedData<[Toplist]>] = [:]

    var smallToplist: [Toplist]?
    var marketToplist: [Toplist]?
    var favorites: [Toplist]?
    var coin: Toplist?
    var favouriteResult: [Toplist] = []
    private(set) var favouritePressCount = 0

    func ensureCacheLoaded() async {}
    func ensureFavoritesLoaded() async {}
    func migrateFavorites() async {}
    func getSmallToplist() async -> [Toplist]? { smallToplist }
    func getMarketToplist(sortOption: SortOption, priceChange: PriceChange, platformId: String?) async -> [Toplist]? { marketToplist }
    func getFavorites() async -> [Toplist]? { favorites }
    func favouriteButtonPressed(toplist: Toplist) async -> [Toplist] {
        favouritePressCount += 1
        return favouriteResult
    }
    func updateFromToplist(coins: [Toplist]) async {}
    func refreshForCurrencyChange(sortOption: SortOption, priceChange: PriceChange) async {}
    func getCoin(id: String) async -> Toplist? { coin ?? smallToplist?.first(where: { $0.id == id }) }
}

actor MockVMCryptoDetailRepository: CryptoDetailRepository {
    var cachedCryptoDetail: [String: CachedData<CurrencyDataModel>] = [:]
    var cachedCryptoPrices: [String: CachedData<PriceVolumeModel>] = [:]
    var cachedCryptoCandles: [String: CachedData<CandleStickChartModel>] = [:]
    var cachedBitcoin: CachedData<CurrencyDataModel>?
    var cachedEthereum: CachedData<CurrencyDataModel>?
    var widgetCurrencies: [Toplist] = []

    var currencyDetails: CurrencyDataModel?
    var currencyPrices: PriceVolumeModel?
    var comparePrices: (PriceVolumeModel?, PriceVolumeModel?) = (nil, nil)
    var bitcoin: CurrencyDataModel?
    var ethereum: CurrencyDataModel?
    var image: UIImage?

    func ensureCacheLoaded() async {}
    func migrateSavedCoins() async {}
    func loadCachedDataForCoin(id: String, chart: TimeCharts) async {}
    func getCurrencyDetails(id: String?) async -> CurrencyDataModel? { currencyDetails }
    func getCurrencyPrices(id: String?, chart: TimeCharts) async -> PriceVolumeModel? { currencyPrices }
    func getCompareCurrencyPrices(mainId: String?, compareId: String?, chart: TimeCharts) async -> (PriceVolumeModel?, PriceVolumeModel?) { comparePrices }
    func getPriceModel(id: String, chart: TimeCharts) async -> PriceVolumeModel? { currencyPrices }
    func getCandleChart(id: String?, days: String) async -> CandleStickChartModel? { nil }
    func getBitcoin() async -> CurrencyDataModel? { bitcoin }
    func getEthereum() async -> CurrencyDataModel? { ethereum }
    func getImage(url: String?) async -> UIImage? { image }
    func connectSignalR(onMessage: (@Sendable (CGSimplePriceUpdate) -> Void)?) async -> Bool { false }
    func getCurrency(coinId: String) async -> Bool { false }
    func getCurrencies(coinIds: [String]) async -> Bool { false }
    func disconnectSignalR() async {}
}

actor MockVMPortfolioRepository: PortfolioRepository {
    var cachedPortfolioPies: CachedPortfolioPies?
    var cachedPortfolioPrices: CachedData<[Cryptocurrency]>?
    var portfolioModels: [PortfolioModel] = []

    var portfolioResult: CachedPortfolioPies?
    var allCurrencies: [Cryptocurrency]?
    var importResult: (CachedPortfolioPies?, [Cryptocurrency]?) = (nil, nil)
    var deleteResult: CachedPortfolioPies?
    var foundTransaction: ((any PortfolioEvent)?, Toplist?) = (nil, nil)

    private(set) var addCoinCount = 0
    private(set) var addTransactionCount = 0
    private(set) var deleteCount = 0
    private(set) var lastAddedId: String?
    private(set) var renamedName: String?

    func ensureCacheLoaded() async {}
    func migratePortfolio() async {}
    func resetData(onlyPies: Bool) {}
    func getPortfolio() async -> CachedPortfolioPies? { portfolioResult ?? cachedPortfolioPies }
    func refreshWallets() async -> CachedPortfolioPies? { cachedPortfolioPies }
    func getPortfolioAllCurrencies() async -> [Cryptocurrency]? { allCurrencies }
    func renameWallet(id: String, address: String, newName: String) async { renamedName = newName }
    func importWallet(walletName: String?, coinData: CurrencyDataModel?, address: String, chain: Chain, isRefreshing: Bool) async -> (CachedPortfolioPies?, [Cryptocurrency]?) {
        importResult
    }
    func addNewCoin(coin: Toplist, event: any PortfolioEvent, allCurrencies: [String: Double]?) async {
        addCoinCount += 1
        lastAddedId = coin.id
    }
    func addNewTransaction(id: String, event: any PortfolioEvent) async {
        addTransactionCount += 1
        lastAddedId = id
    }
    func deletePortfolioItem(id: String) async {}
    func deleteTransaction(id: String, uuid: UUID?) async -> CachedPortfolioPies? {
        deleteCount += 1
        return deleteResult
    }
    func findTransaction(lookup: String) async -> ((any PortfolioEvent)?, Toplist?) { foundTransaction }
    func getCoinColors() async -> AsyncStream<[Pie]> { AsyncStream { $0.finish() } }
}

actor MockVMTrendingRepository: TrendingRepository {
    var cachedTrending: CachedData<TrendingItems>?
    var cachedTrendingCoins: CachedData<[Toplist]>?
    var trendingList: TrendingItems?
    var trendingCoins: [Toplist]?

    func ensureCacheLoaded() async {}
    func getTrendingCoins() async -> [Toplist]? { trendingCoins }
    func getTrendingList() async -> TrendingItems? { trendingList }
    func updateFromToplist(coins: [Toplist]) {}
}

actor MockVMNewsRepository: NewsRepository {
    var selectedNewsType: NewsType = .general
    var cachedNews: [NewsType: CachedData<NewsModel>] = [:]
    var news: [NewsItem]?
    private(set) var updatedType: NewsType?

    func ensureCacheLoaded() async {}
    func getNews(type: NewsType, count: Int) async -> [NewsItem]? { news }
    func updateNewsType(_ type: NewsType) async { updatedType = type }
}

actor MockVMSearchRepository: SearchRepository {
    var cachedSearches: [String: CachedData<SearchModel>] = [:]
    var result: SearchModel?

    func ensureCacheLoaded() async {}
    func getSearchResult(query: String) async -> SearchModel? { result }
}

actor MockVMCalculatorRepository: CalculatorRepository {
    var cachedPrices: CachedData<[Cryptocurrency]>?
    var prices: [Cryptocurrency]?

    func ensureCacheLoaded() async {}
    func getCalculatorPrices(ids: [String]) async -> [Cryptocurrency]? { prices }
}

actor MockVMPriceAlertsRepository: PriceAlertsRepository {
    var cachedPriceAlerts: CachedData<[AlertCoin]>?
    var cachedAlertPrices: CachedData<[Cryptocurrency]>?

    var hasFCMToken = true
    var alerts: [AlertCoin]?
    var createdAlerts: [AlertCoin]?
    var deletedAlerts: [AlertCoin]?
    var alertPrices: [Cryptocurrency]?
    var remainingCoins: [Toplist]?
    var bigMoverSubscribed = true
    var feedbackResult = true

    func ensureCacheLoaded() async {}
    func ensureFCMToken() async -> Bool { hasFCMToken }
    func updateUser(fcmToken: String) async {}
    func triggerPriceAlert() async {}
    func triggerBigMover() async {}
    func getAlertPrices(ids: [String]) async -> [Cryptocurrency]? { alertPrices }
    func downloadRemainingCoins(ids: [String], withSparkline: Bool) async -> [Toplist]? { remainingCoins }
    func subBigMovers() async -> Bool { bigMoverSubscribed }
    func ubsubBigMovers() async -> Bool { bigMoverSubscribed }
    func sendFeedback(rating: Int, feedback: String?) async -> Bool { feedbackResult }
    func getAlerts() async -> [AlertCoin]? { alerts }
    func createPriceAlert(alert: PostAlertCoin) async -> [AlertCoin]? { createdAlerts }
    func deleteAlert(alertId: String) async -> [AlertCoin]? { deletedAlerts }
    func deleteLocalAlert(alertId: String) async {}
}

actor MockVMDerivativesRepository: DerivativesRepository {
    var cachedDerivatives: [String: CachedData<[Derivative]>] = [:]
    var derivatives: [Derivative]?

    func ensureCacheLoaded() async {}
    func getDerivatives(sortOption: SortOption) async -> [Derivative]? { derivatives }
}

actor MockVMDerivativeDetailsRepository: DerivativeDetailsRepository {
    var cachedDerivatives: [String: CachedData<Derivative>] = [:]
    var detail: Derivative?

    func ensureCacheLoaded() async {}
    func getDerivativeDetail(id: String?) async -> Derivative? { detail }
    func getExchangeImage(imageUrl: String?) async -> Data? { nil }
}

actor MockVMExchangesRepository: ExchangesRepository {
    var cachedExchanges: CachedData<[ExchangeModel]>?
    var exchanges: [ExchangeModel]?

    func ensureCacheLoaded() async {}
    func getExchanges() async -> [ExchangeModel]? { exchanges }
}

actor MockVMCategoriesRepository: CategoriesRepository {
    var cachedCategories: [String: CachedData<[CryptoCategory]>] = [:]
    var categories: [CryptoCategory]?

    func ensureCacheLoaded() async {}
    func getCategories(sortOption: SortOption) async -> [CryptoCategory]? { categories }
}

actor MockVMFearGreedRepository: FearGreedRepository {
    var cachedFearGreed: CachedData<FearGreed>?
    var fearGreed: FearGreed?

    func ensureCacheLoaded() async {}
    func getFearGreed() async -> FearGreed? { fearGreed }
}

actor MockVMGlobalMarketRepository: GlobalMarketRepository {
    var cachedGlobalMarket: CachedData<GlobalMarketModel?>?
    var cachedGlobalChart: CachedData<GlobalMarketChartModel?>?
    var cachedCoinList: CachedData<[CoinsListModel]>?
    var coins: [CoinsListModel]?
    var market: GlobalMarketModel?
    var chart: GlobalMarketChartData?

    func ensureCacheLoaded() async {}
    func getAllCoins() async -> [CoinsListModel]? { coins }
    func getGlobalMarket() async -> GlobalMarketModel? { market }
    func getGlobalChart(days: String) async -> GlobalMarketChartData? { chart }
    func getColors() async -> AsyncStream<GlobalMarketModel?> { AsyncStream { $0.finish() } }
}

actor MockVMGasFeesRepository: GasFeesRepository {
    var cachedGasFees: CachedData<GasFees>?
    var cachedGasFeePrices: CachedData<GasFees>?
    var gasFees: GasFees?
    var gasFeePrices: GasFees?

    func ensureCacheLoaded() async {}
    func getGasFees() async -> GasFees? { gasFees }
    func getGasFeePrices() async -> GasFees? { gasFeePrices }
}

actor MockVMReferralRepository: ReferralRepository {
    var cachedUser: CachedData<UserResponse>?
    var cachedReferralCode: CachedData<CachedReferralCodeData>?
    var referralCode: ReferralCodeResult?
    var redeemResult: RedeemCodeResult = .failure
    var user: UserResponse?

    func ensureCacheLoaded() async {}
    func getReferralCode() async -> ReferralCodeResult? { referralCode }
    func redeemCode(refCode: String) async -> RedeemCodeResult { redeemResult }
    func getUser(ignoreCache: Bool) async -> UserResponse? { user }
}

actor MockVMNFTRepository: NFTRepository {
    var cachedToplist: [String: CachedData<[NFTToplist]>] = [:]
    var cachedPlatforms: CachedData<[NFTPlatform]>?
    let toplistSubject = PassthroughSubject<Result<[NFTToplist], Error>, Error>()
    var toplist: [NFTToplist]?
    var platforms: [NFTPlatform]?

    func ensureCacheLoaded() async {}
    func getToplist(platform: NFTPlatform, sortOption: SortOption) async -> [NFTToplist]? { toplist }
    func getNFTPlatforms() async -> [NFTPlatform]? { platforms }
}

actor MockVMNFTDetailRepository: NFTDetailRepository {
    var cachedNFTDetails: [String: CachedData<NFTDetail>] = [:]
    var cachedNFTPrices: [String: CachedData<NFTPriceVolumeModel>] = [:]
    var cachedNFTTickers: [String: CachedData<[NFTTicker]>] = [:]
    var detail: NFTDetail?
    var prices: NFTPriceVolumeModel?
    var tickers: [NFTTicker]?

    func ensureCacheLoaded() async {}
    func loadCachedDataForNFT(id: String, days: String) async {}
    func getNFTDetail(id: String?) async -> NFTDetail? { detail }
    func getNFTPrices(id: String?, days: String) async -> NFTPriceVolumeModel? { prices }
    func getNFTTickers(id: String?) async -> [NFTTicker]? { tickers }
    func getImage(url: String?) async -> UIImage? { nil }
}

actor MockVMExchangeDetailsRepository: ExchangeDetailsRepository {
    var cachedExchangeDetail: [String: CachedData<Exchange>] = [:]
    var cachedExchangePrices: [String: CachedData<[ExchangePriceModel]>] = [:]
    var detail: Exchange?
    var prices: [ExchangePriceModel]?

    func ensureCacheLoaded() async {}
    func loadCachedDataForExchange(id: String, days: String) async {}
    func getExchangeDetails(id: String?) async -> Exchange? { detail }
    func getExchangePrices(id: String?, days: String) async -> [ExchangePriceModel]? { prices }
}

actor MockVMTreasuryDetailRepository: TreasuryDetailRepository {
    var cachedTreasuryDetails: [String: CachedData<TreasuryDetailEntity>] = [:]
    var cachedHoldingCharts: [String: CachedData<TreasuryHoldingChartModel>] = [:]
    var cachedTransactionHistory: [String: CachedData<TreasuryTransactionHistoryModel>] = [:]
    var detail: TreasuryDetailEntity?
    var chart: TreasuryHoldingChartModel?
    var history: TreasuryTransactionHistoryModel?

    func ensureCacheLoaded() async {}
    func loadCachedDataForTreasury(id: String, coinId: String, days: String) async {}
    func getTreasuryDetail(id: String?) async -> TreasuryDetailEntity? { detail }
    func getHoldingChart(id: String?, coinId: String, days: String) async -> TreasuryHoldingChartModel? { chart }
    func getTransactionHistory(id: String?, coinId: String?) async -> TreasuryTransactionHistoryModel? { history }
}

actor MockVMWinnersLosersRepository: WinnersLosersRepository {
    var cachedWinnersLosers: [String: CachedData<WinnersLosers>] = [:]
    var cachedWinnersCoins: [String: CachedData<[Toplist]>] = [:]
    var cachedLosersCoins: [String: CachedData<[Toplist]>] = [:]
    var winners: [Toplist]?
    var losers: [Toplist]?

    func ensureCacheLoaded() async {}
    func getWinners(priceChange: PriceChange) async -> [Toplist]? { winners }
    func getLosers(priceChange: PriceChange) async -> [Toplist]? { losers }
    func getWinnersLosersList(priceChange: PriceChange) async -> WinnersLosers? { nil }
    func updateFromToplist(coins: [Toplist]) {}
}

actor MockVMNewCoinsRepository: NewCoinsRepository {
    var cachedNewCoins: CachedData<[Toplist]>?
    var newCoins: [Toplist]?

    func ensureCacheLoaded() async {}
    func getNewCoins() async -> [Toplist]? { newCoins }
    func getActualCoins(ids: [String]) async -> [Toplist]? { newCoins }
    func updateFromToplist(coins: [Toplist]) {}
}
