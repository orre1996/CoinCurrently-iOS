//
//  TrackerViewModel.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-23.
//

import Foundation
import SwiftUI
import Combine
@preconcurrency import UserNotifications

@MainActor
protocol CryptoDetailViewModel {
    var hoverHelper: HoverHelper { get set }
    var hoverPriceWidthSize: CGFloat { get set }
    var hoverTimeWidthSize: CGFloat { get set }
    var hoverCandleTimeWidthSize: CGFloat { get set }
    var chartSize: CGSize { get set }
    var globalMarketData: GlobalMarketModel? { get set }
    var showMainPriceError: Bool { get set }
    var cryptoInfo: CurrencyDataModel? { get set }
    var priceVolumeModel: PriceVolumeModel? { get set }
    var prices: [Double] { get set }
    var onlyPrices: [Double] { get set }
    var volumes: [Double] { get set }
    var timeStamps: [Double] { get set }
    var currencyLogo: UIImage? { get set }
    var mainReloading: Bool { get set }
    var showMainGraph: Bool { get set }
    var inFavoritesList: Bool { get set }
    var candleSticksModel: CandleStickChartModel? { get set }
    var candleSticks: [Candle] { get set }
    var candleInfoLeftSide: Bool { get set }
    var news: [NewsItem] { get set }
    var showNewsError: Bool { get set }
    var alerts: [AlertCoin]? { get set }
    var isGraphLinear: Bool { get set }
    var currentChartType: ChartTypes { get set }
    var candleChartEnabled: Bool { get set }
    var currentDays: String { get set }
    var selectedTimeFrame: TimeCharts { get set }
    var widgetCurrencies: [Toplist] { get set }
    var isDragging: Bool { get set }
    var showDetailNews: Bool { get set }
    var selectedSortOption: SortOption { get set }
    var exchangeMarketItems: [ExchangeMarketItem]? { get set }
    var pie: Pie? { get set }
    var isWebSocketEnabled: Bool { get }
    var portfolio: [Pie]? { get set }
    var allPrices: [Cryptocurrency] { get }
    var hidePortfolioData: Bool { get set }
    var groupedTransactions: [Date: [any PortfolioEvent]]? { get }
    func getAllpriceAlertsCount() async -> Int
    func setNewSortOption(newSortOption: SortOption) async
    
    var changePercent: Double? { get }
    var mainGraphStats: [String?] { get }
    var isCandleChartEnabled: Bool { get }
    var candlePrices: [Double] { get }
    var highestCandleValue: Double? { get }
    var lowestCandleValue: Double? { get }
    var candleTimestamps: [Double] { get }
    var candleMiddlePrices: [Double] { get }
    var differenceValue: String { get }
    var differencePercent: String { get }
    var graphColor: Color { get }
    var hoverTime: String { get }
    var hoverPrice: String { get }
    var hoverTimePosition: CGFloat { get }
    var hoverPricePosition: CGFloat { get }
    var hoverCandleTimePosition: CGFloat { get }
    var mainDragIndex: [Int] { get }
    var dragPositions: [CGPoint] { get }
    var pointCandle: CGPoint { get }

    func setStartData() async
    func point(at index: Int, rect: CGSize) -> CGPoint
    func getGlobalMarketData() async
    func getPortfolio() async
    func setGroupTransactions()
    func deleteTransaction(_ transaction: (any PortfolioEvent)?) async
    func findTransaction(transaction: String) async -> ((any PortfolioEvent)?, Toplist?)
    func hasPro() async -> Bool
    func toggleHideData()
    
    func getNews(forceSymbol: String?) async
    func refresh(showReload: Bool, newDays: String?, newTimeChart: TimeCharts?, forceId: String?, getNews: Bool, forceSymbol: String?) async
    func addCurrencyToWidgets() async
    func replaceWidgetCurrency(coin: Toplist, with: Toplist?) async
    func toggleChart() async
    func getMainCryptoInfo(id: String?) async
    func getMainCurrencyPrices(id: String?, chart: TimeCharts) async
    func newMainCoin(id: String) async
    func hasBoughtPro() async -> Bool
    func handleFavoriteButtonPressed() async
    func setChartType(type: ChartTypes)
    func getPrices() -> [Double]
    func getTimestamps() -> [Double]
    func getPriceInChart(prices: [Double], at index: Int) -> String?
    func getCandleChart(id: String?, days: String) async
    func getPriceCandleInChart(at index: Int) -> String?
    #if IS_APP
    func checkIfUserEnabledPush() async -> Bool
    #endif
    func getPriceAlerts() async
    func addPriceAlert(alertCoin: PostAlertCoin) async -> AddPriceAlertResult
    func deleteAlert(alert: AlertCoin) async
    func shareDetails()
    func updateHoverStats(touches: [CGPoint])
    func stopLivePriceUpdates() async
}

@MainActor @Observable
final class CryptoDetailViewModelImp: CryptoDetailViewModel {
    
    private let cryptoDetailRepository: CryptoDetailRepository
    private let portfolioRepository: PortfolioRepository
    private let newsRepository: NewsRepository
    private let toplistRepository: ToplistRepository
    private let trendingRepository: TrendingRepository
    private let globalMarketRepository: GlobalMarketRepository
    private let storageManager: CachedStorageManager
    private let storeKitManager: StoreKitManager
    private let priceAlertsRepository: PriceAlertsRepository
    private let firebaseManager: FirebaseManager
    private let analyticsManager: AnalyticsManager
    private let settingsManager: SettingsManager
    
    // Hover
    var hoverHelper = HoverHelper()
    
    var hoverPriceWidthSize: CGFloat = 0
    var hoverTimeWidthSize: CGFloat = 0
    var hoverCandleTimeWidthSize: CGFloat = 0
    var chartSize: CGSize = .zero
    
    var globalMarketData: GlobalMarketModel?
    
    // Main coin
    var showMainPriceError: Bool = false
    var cryptoInfo: CurrencyDataModel?
    var priceVolumeModel: PriceVolumeModel?
    var prices = [Double]()
    var onlyPrices = [Double]()
    var volumes = [Double]()
    var timeStamps = [Double]()
    var currencyLogo: UIImage?
    var mainReloading = true
    var showMainGraph = true
    var inFavoritesList = false
    
    // Candle sticks
    var candleSticksModel: CandleStickChartModel?
    var candleSticks = [Candle]()
    var candleInfoLeftSide = true
    
    // News
    var news = [NewsItem]()
    var showNewsError = false
    
    // Portfolio
    var pie: Pie?
    var portfolio: [Pie]?
    var allPrices = [Cryptocurrency]()
    var hidePortfolioData: Bool
    var groupedTransactions: [Date : [any PortfolioEvent]]? = nil
    
    // Alerts
    var alerts: [AlertCoin]?
    
    // General
    var isGraphLinear: Bool = SettingsManager.shared.get(key: AppSettingKey.isGraphLinear) ?? true
    var currentChartType: ChartTypes = SettingsManager.shared.get(key: AppSettingKey.graphType) ?? .price
    var candleChartEnabled = SettingsManager.shared.getCandleChartSelected()
    var currentDays = TimeCharts.getStartTimeFrame(between: .anHour, and: .max).days
    var selectedTimeFrame = TimeCharts.getStartTimeFrame(between: .anHour, and: .max)
    var widgetCurrencies = [Toplist]()
    var isDragging = false
    
    var showDetailNews = false
    
    var selectedSortOption: SortOption = .volumeDesc
    var exchangeMarketItems: [ExchangeMarketItem]? = nil
    
    private var timer: Timer?
    
    private(set) var hasProSubscription = false
    
    var isWebSocketEnabled: Bool {
        settingsManager.isWebSocketEnabled(hasPro: hasProSubscription)
    }
    
    init(
        cryptoInfo: CurrencyDataModel,
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared,
        newsRepository: NewsRepository = NewsRepositoryImp.shared,
        portfolioRepository: PortfolioRepository = PortfolioRepositoryImp.shared,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        trendingRepository: TrendingRepository = TrendingRepositoryImp.shared,
        globalMarketRepository: GlobalMarketRepository = GlobalMarketRepositoryImp.shared,
        storageManager: CachedStorageManager = CachedStorageManagerImp.shared,
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared,
        priceAlertsRepository: PriceAlertsRepository = PriceAlertsRepositoryImp.shared,
        firebaseManager: FirebaseManager = FirebaseManagerImp.shared,
        analyticsManager: AnalyticsManager = AnalyticsManager.shared,
        settingsManager: SettingsManager = SettingsManager.shared
    ) {
        self.cryptoDetailRepository = cryptoDetailRepository
        self.portfolioRepository = portfolioRepository
        self.newsRepository = newsRepository
        self.toplistRepository = toplistRepository
        self.trendingRepository = trendingRepository
        self.globalMarketRepository = globalMarketRepository
        self.storageManager = storageManager
        self.storeKitManager = storeKitManager
        self.priceAlertsRepository = priceAlertsRepository
        self.firebaseManager = firebaseManager
        self.analyticsManager = analyticsManager
        self.settingsManager = settingsManager
        
        self.cryptoInfo = cryptoInfo
        self.hidePortfolioData = settingsManager.get(key: AppSettingKey.hidePortfolioValues) ?? false
    }
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await toplistRepository.ensureCacheLoaded()
        await priceAlertsRepository.ensureCacheLoaded()
        
        hasProSubscription = await storeKitManager.currentSubscription != nil

        let coinId = cryptoInfo?.id ?? ""
        if !coinId.isEmpty {
            await cryptoDetailRepository.loadCachedDataForCoin(id: coinId, chart: selectedTimeFrame)
        }
        let detail = await cryptoDetailRepository.cachedCryptoDetail[coinId]?.data
        self.cryptoInfo = detail ?? cryptoInfo

        let priceCacheKey = "\(coinId)-\(selectedTimeFrame.days)"
        if let priceData = await cryptoDetailRepository.cachedCryptoPrices[priceCacheKey]?.data {
            self.priceVolumeModel = priceData

            setPrices()
            setOnlyPrices()
            setVolumes()
            setTimestamps()
            
            self.mainReloading = isCandleChartEnabled
        }
        
        let candleCacheKey = "\(coinId)-\(currentDays)"
        if isCandleChartEnabled, let candleStickModel = await cryptoDetailRepository.cachedCryptoCandles[candleCacheKey]?.data {
            self.candleSticksModel = candleStickModel
            setCandleSticks()
            self.mainReloading = false
        }
        
        self.widgetCurrencies = await cryptoDetailRepository.widgetCurrencies
        
        if let globalData = await globalMarketRepository.cachedGlobalMarket?.data {
            globalMarketData = globalData
        }
        
        inFavoritesList = await toplistRepository.cachedFavorites?.data.contains { $0.id == cryptoInfo?.id } ?? false

        showDetailNews = await firebaseManager.getConfigBool(key: .showDetailNews) ?? false

        if let symbol = cryptoInfo?.symbol?.uppercased(),
           let newsData = await newsRepository.cachedNews[.coin(symbol: symbol)]?.data.data {
            self.news = newsData
        }

        selectedSortOption = await storageManager.load(type: AppSettingKey.cryptoDetailSortOption.rawValue) ?? .volumeDesc
        await updateExchangeMarketItems()
    }

    func setNewSortOption(newSortOption: SortOption) async {
        selectedSortOption = newSortOption
        await storageManager.save(type: AppSettingKey.cryptoDetailSortOption.rawValue, data: selectedSortOption)
        await updateExchangeMarketItems()
    }

    private func updateExchangeMarketItems() async {
        guard let tickers = cryptoInfo?.tickers else {
            exchangeMarketItems = nil
            return
        }
        
        exchangeMarketItems = tickers.map { ExchangeMarketItem.from($0) }.sorted(by: selectedSortOption)
    }
    
    // MARK: - Computed properties
    
    func getAllpriceAlertsCount() async -> Int {
        await priceAlertsRepository.cachedPriceAlerts?.data.count ?? 0
    }
    
    var changePercent: Double? {
        if isCandleChartEnabled {
            guard let open = candleSticks.first?.open,
                  let close = candleSticks.last?.close else {
                return nil
            }
            
            return Double.getDifferenceInPercent(between: close, and: open)
        } else {
            guard let first = getPrices().first,
                  let last = getPrices().last else {
                return nil
            }
            
            return Double.getDifferenceInPercent(between: last, and: first)?.roundTo(places: 7)
        }
    }
    
    var mainGraphStats: [String?] {
        return (0..<6).map({ isCandleChartEnabled ? getPriceCandleInChart(at: $0) : getPriceInChart(prices: getPrices(), at: $0) })
    }

    var isCandleChartEnabled: Bool {
        return candleChartEnabled
    }
    
    var candlePrices: [Double] {
        guard let first = candleSticks.first?.open,
              let last = candleSticks.last?.close,
              !candleSticks.isEmpty else {
            return []
        }

        let highs = candleSticks.compactMap(\.high)
        let lows = candleSticks.compactMap(\.low)

        let max = highs.max() ?? 0
        let min = lows.min() ?? 0

        return [first, max, min, last]
    }
    
    var highestCandleValue: Double? {
        return candleSticks.compactMap({ $0.high ?? 0 }).max()
    }
    
    var lowestCandleValue: Double? {
        return candleSticks.compactMap({ $0.low ?? 0 }).min()
    }
    
    var candleTimestamps: [Double] {
        return candleSticks.compactMap({ $0.timestamp ?? 0 })
    }
    
    var candleMiddlePrices: [Double] {
        candleSticks.map { (($0.low ?? 0.0) + ($0.high ?? 0.0)) / 2 }
    }

    var differenceValue: String {
        let first = hoverHelper.hoverPrices[safely: 0] ?? 0
        let second = hoverHelper.hoverPrices[safely: 1] ?? 0
        let percent = Double.getDifferenceInPercent(between: second, and: first)?.safeValue ?? 0
        let sign = percent.roundTo(places: 2) < 0 ? "" : "+"
        let difference = (second - first).formatCurrency(threshold: FormattingThreshold.million)
        return "\(sign)\(difference)"
    }
    
    var differencePercent: String {
        let first = hoverHelper.hoverPrices[safely: 0] ?? 0
        let second = hoverHelper.hoverPrices[safely: 1] ?? 0.0
        let difference = Double.getDifferenceInPercent(between: second, and: first) ?? 0
        let sign = difference >= 0 ? "+" : "-"
        
        return "\(sign)\(difference.safeValue.removeZerosFromEnd(force: true).withoutSymbol)%"
    }
    
    var graphColor: Color {
        guard hoverHelper.hoverPrices.count == 2, isDragging else {
            return changePercent?.changeColor ?? .onSurfaceDim
        }
        
        let first = hoverHelper.hoverPrices[safely: 0] ?? 0
        let second = hoverHelper.hoverPrices[safely: 1] ?? 0
        let change = (second - first).roundTo(places: 7)
        
        if change == 0 {
            let percent = Double.getDifferenceInPercent(between: second, and: first)?.roundTo(places: 7)
            return percent?.changeColor ?? .onSurfaceDim
        }
        
        return change.changeColor
    }
    
    var hoverTime: String {
        return hoverHelper.hoverTimes.first ?? "0"
    }
    
    var hoverPrice: String {
        return hoverHelper.hoverPrices.first?.formatCurrency(threshold: FormattingThreshold.million) ?? "0"
    }
    
    var hoverTimePosition: CGFloat {
        return getXPosition(textSize: hoverTimeWidthSize) - hoverTimeWidthSize / 2
    }
    
    var hoverPricePosition: CGFloat {
        return getXPosition(textSize: hoverPriceWidthSize) - hoverTimeWidthSize / 2
    }

    var hoverCandleTimePosition: CGFloat {
        return getCandleXPosition(textSize: hoverCandleTimeWidthSize) - hoverCandleTimeWidthSize / 2
    }
    
    var mainDragIndex: [Int] {
        let timestamps = getTimestamps()
        let pricesCount = CGFloat(getPrices().count)
        let firstTimestamp = timeStamps.normalized.first ?? 0
        let timestampCount = Double(timestamps.count)
        
        return hoverHelper.offset.map { offsetPoint in
            let offsetRatio = offsetPoint.x / chartSize.width
            guard offsetRatio >= firstTimestamp else { return -1 }
            
            let indexOffset = timestampCount * firstTimestamp
            let maxIndex = max(0, Int(pricesCount))
            let spatialIndex = Double(maxIndex) * Double(offsetPoint.x / chartSize.width)
            let index = spatialIndex - indexOffset
            
            if index.isNaN || index.isInfinite {
                return -1
            }
            
            return Int(index)
        }
    }
    
    var dragPositions: [CGPoint] {
        return mainDragIndex.map({
            point(at: $0, rect: CGSize(width: chartSize.width, height: chartSize.height))
        })
    }

    func point(at index: Int, rect: CGSize) -> CGPoint {
        return calculatePoint(
            at: index,
            rect: rect,
            timestamps: getTimestamps(),
            prices: getPrices()
        )
    }

    private var currentCandleHoverIndex: Int {
        guard chartSize.width > 0 else { return 0 }
        
        let hoverPoint = hoverHelper.offset.map { $0.x }.first ?? 0
        
        return candleBinIndex(x: hoverPoint, width: chartSize.width, candleCount: candleSticks.count)
    }
    
    private var currentHoverIndex: Int {
        guard chartSize.width > 0 else { return 0 }
        
        let hoverPoints = hoverHelper.offset.map { $0.x }
        let hoverPoint: CGFloat
        
        if hoverHelper.hoverPrices.count == 2 {
            hoverPoint = hoverPoints.reduce(0, +) / 2
        } else {
            hoverPoint = hoverPoints.first ?? 0
        }
        
        return chartLinearSeriesIndex(x: hoverPoint, width: chartSize.width, pointCount: getPrices().count)
    }
    
    // MARK: - Download data functions

    func getGlobalMarketData() async {
        if let globalMarketData = await globalMarketRepository.getGlobalMarket() {
            self.globalMarketData = globalMarketData
        }
    }
    
    func getPortfolio() async {
        async let portfolioTask = portfolioRepository.getPortfolio()
        async let currenciesTask = portfolioRepository.getPortfolioAllCurrencies()
        
        // Wait for both network calls to complete
        let fetchedPortfolio = await portfolioTask
        let allCurrencies = await currenciesTask
        
        portfolio = fetchedPortfolio?.data
        allPrices = allCurrencies ?? []
        pie = portfolio?.first(where: { $0.data?.id == cryptoInfo?.id })
        setGroupTransactions()
    }
    
    func setGroupTransactions() {
        guard let portfolio = portfolio else {
            groupedTransactions = [:]
            return
        }
        
        let coinSlices = portfolio.filter({ $0.data?.id == cryptoInfo?.id }).compactMap({ $0.data })
        var result = coinSlices.isEmpty ? [:] : portfolio.groupedTransactions(
            types: [],
            on: .all,
            coinNames: coinSlices
        )
        
        if let targetId = cryptoInfo?.id {
            let calendar = Calendar.current
            var seenIds = Set(result.values.flatMap { $0.map(\.id) })
            
            for swap in portfolio.flatMap({ $0.swaps }).filter({ $0.fromCurrencyId == targetId }) {
                guard !seenIds.contains(swap.id) else { continue }
                seenIds.insert(swap.id)
                let day = calendar.startOfDay(for: swap.date)
                result[day, default: []].append(swap)
            }
            
            for key in result.keys {
                result[key]?.sort { $0.date > $1.date }
            }
        }
        
        groupedTransactions = result
    }
    
    func deleteTransaction(_ transaction: (any PortfolioEvent)?) async {
        guard let transaction else {
            return
        }
        
        let id = portfolio?.pie(containing: transaction)?.data?.id ?? ""

        portfolio = await portfolioRepository.deleteTransaction(
            id: id,
            uuid: transaction.id
        )?.data
        
        pie = portfolio?.first(where: { $0.data?.id == cryptoInfo?.id })

        setGroupTransactions()
    }
    
    func findTransaction(transaction: String) async -> ((any PortfolioEvent)?, Toplist?) {
        await portfolioRepository.findTransaction(lookup: transaction)
    }
    
    func hasPro() async -> Bool {
        return await storeKitManager.currentSubscription != nil
    }
    

    func toggleHideData() {
        hidePortfolioData.toggle()
        settingsManager.set(data: hidePortfolioData, key: AppSettingKey.hidePortfolioValues)
    }
    
    func getNews(forceSymbol: String? = nil) async {
        guard let showNews = await FirebaseManagerImp.shared.getConfigBool(key: .showDetailNews), showNews, let id = forceSymbol?.uppercased() ?? cryptoInfo?.symbol?.uppercased() else { return }
        
        showNewsError = false
        
        if let news = await newsRepository.getNews(type: .coin(symbol: id), count: 25), !news.isEmpty {
            self.news = news
        } else {
            showNewsError = true
        }
    }
    
    func refresh(
        showReload: Bool = true,
        newDays: String? = nil,
        newTimeChart: TimeCharts? = nil,
        forceId: String? = nil,
        getNews: Bool = false,
        forceSymbol: String? = nil
    ) async {
        mainReloading = showReload
        
        hasProSubscription = await storeKitManager.currentSubscription != nil
        
        let days = newDays ?? self.currentDays
        let chart = newTimeChart ?? self.selectedTimeFrame
        let mainId = forceId ?? self.cryptoInfo?.id
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.getMainCryptoInfo(id: mainId) }
            
            if getNews {
                group.addTask { await self.getNews(forceSymbol: forceSymbol) }
            }
            
            if isCandleChartEnabled {
                group.addTask { await self.getCandleChart(id: mainId, days: days) }
            } else {
                group.addTask { await self.getMainCurrencyPrices(id: mainId, chart: chart) }
            }
        }
        
        currentDays = days
        selectedTimeFrame = chart
        
        if !showMainPriceError {
            setPrices()
            setOnlyPrices()
            setVolumes()
            setTimestamps()
        }
        
        if self.isCandleChartEnabled {
            setCandleSticks()
        }
        
        mainReloading = false
        
        if let mainId {
            await startWebSocket(for: mainId)
        }
    }
    
    // MARK: - Main coin functions
    
    func addCurrencyToWidgets() async {
        guard let cryptoInfo else { return }

        let toplistItem = cryptoInfo.toToplist()

        widgetCurrencies.append(toplistItem)
        await cryptoDetailRepository.addCurrencyToWidget(toplist: toplistItem)
    }
    
    func replaceWidgetCurrency(coin: Toplist, with: Toplist? = nil) async {
        guard let cryptoInfo, let index = widgetCurrencies.firstIndex(where: { $0.id == coin.id }) else { return }
        
        let toplistItem = with ?? cryptoInfo.toToplist()
        
        widgetCurrencies[index] = toplistItem
        await cryptoDetailRepository.replacedWidget(at: index, toplist: toplistItem)
    }
    
    func toggleChart() async {
        mainReloading = true
        candleChartEnabled.toggle()
        SettingsManager.shared.setCandleChart(enabled: candleChartEnabled)
        AchievementManager.shared.increment(.candleChartToggles)
        
        if candleChartEnabled {
            await getCandleChart(id: cryptoInfo?.id, days: currentDays)
        } else {
            await getMainCurrencyPrices(id: cryptoInfo?.id, chart: selectedTimeFrame)
        }
        
        setPrices()
        setOnlyPrices()
        setVolumes()
        setTimestamps()
        
        if self.isCandleChartEnabled {
            setCandleSticks()
        }
        
        mainReloading = false
    }
    
    func getMainCryptoInfo(id: String?) async {
        guard let cryptoDetails = await cryptoDetailRepository.getCurrencyDetails(id: id) else { return }

        cryptoInfo = cryptoDetails
        await updateExchangeMarketItems()
        inFavoritesList = await toplistRepository.cachedFavorites?.data.contains(where: { $0.id == id }) ?? false

        guard let image = await cryptoDetailRepository.getImage(url: cryptoDetails.image?.small) else { return }
        currencyLogo = image
    }
    
    func getMainCurrencyPrices(
        id: String?,
        chart: TimeCharts
    ) async {
        priceVolumeModel = await cryptoDetailRepository.getCurrencyPrices(
            id: id,
            chart: chart
        )

        showMainPriceError = priceVolumeModel == nil
    }
    
    func newMainCoin(id: String) async {
        await stopWebSocket()
        mainReloading = true
        showMainGraph = true
        cryptoInfo = nil
        priceVolumeModel = nil
        
        setPrices()
        setOnlyPrices()
        setVolumes()
        setTimestamps()

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.getMainCryptoInfo(id: id) }
            
            if isCandleChartEnabled {
                group.addTask { await self.getCandleChart(id: id, days: self.currentDays) }
            } else {
                group.addTask { await self.getMainCurrencyPrices(id: id, chart: self.selectedTimeFrame) }
            }
        }

        setPrices()
        setOnlyPrices()
        setVolumes()
        setTimestamps()
        
        mainReloading = false
        
        await startWebSocket(for: id)
    }
    
    func hasBoughtPro() async -> Bool {
        await storeKitManager.currentSubscription != nil
    }
    
    func handleFavoriteButtonPressed() async {
        guard let toplistItem = cryptoInfo?.toToplist() else { return }
        
        let hasActiveSubscription = await storeKitManager.currentSubscription != nil
        
        // temp
        let favorites: CachedData<[Toplist]>? = await CoreDataManager.shared.get(forKey: .favorites)
        if !hasActiveSubscription && !inFavoritesList && (favorites?.data.count ?? 0) >= 2 {
            analyticsManager.log(
                BuyProOpened(fromScreen: .cryptoDetail, action: .Favorite)
            )
            showBuyPro()
            return
        }
        
        if inFavoritesList {
            analyticsManager.log(FavoriteRemoved(coinName: toplistItem.name ?? "", fromScreen: .cryptoDetail))
        } else {
            analyticsManager.log(FavoriteAdded(coinName: toplistItem.name ?? "", fromScreen: .cryptoDetail))
        }
        
        inFavoritesList.toggle()
        
        _ = await toplistRepository.favouriteButtonPressed(toplist: toplistItem)
    }
    
    func setChartType(type: ChartTypes) {
        currentChartType = type
        SettingsManager.shared.set(data: currentChartType, key: AppSettingKey.graphType)
        
        setPrices()
    }
    
    func getPrices() -> [Double] {
        return prices
    }
    
    func getTimestamps() -> [Double] {
        guard !showMainPriceError else { return [] }
  
        return Array(timeStamps)
    }
    
    func getPriceInChart(prices: [Double], at index: Int) -> String? {
        guard !showMainPriceError,
              let minPrice = prices.min(),
              let maxPrice = prices.max() else {
                  return nil
              }
        
        let step = (maxPrice - minPrice) / 5
        let value = minPrice + (step * Double(index))
        
        return value.formatCurrency(currency: CurrencyModel.empty)
    }
    
    // MARK: - Candle chart
    
    func getCandleChart(id: String?, days: String) async {
        candleSticksModel = await cryptoDetailRepository.getCandleChart(id: id, days: days)
        showMainPriceError = candleSticksModel == nil
    }
    
    func getPriceCandleInChart(at index: Int) -> String? {
        guard let minValue = lowestCandleValue,
              let maxValue = highestCandleValue else {
            return nil
        }
        
        let step = (maxValue - minValue) / 5
        let value = minValue + (step * Double(index))
        
        return value.formatCurrency(currency: CurrencyModel.empty)
    }
    
    var pointCandle: CGPoint {
        guard !candleSticks.isEmpty, let hoverX = hoverHelper.offset.first?.x else {
            return .zero
        }

        // Prepare normalized prices including highest and lowest values
        var prices = candleMiddlePrices
        if let highest = candleSticks.compactMap({ $0.high }).max(),
           let lowest = candleSticks.compactMap({ $0.low }).min() {
            prices.append(highest)
            prices.append(lowest)
        }

        prices = prices.normalized

        // Remove the added highest and lowest after normalization
        if prices.count >= 2 {
            prices.removeLast(2)
        }

        let scale = chartSize.width / hoverX
        let index = Int(CGFloat(candleSticks.count) / scale)
        let safeIndex = min(index, prices.count - 1)

        let point = prices[safely: safeIndex] ?? 0

        var x = chartSize.width * Double(safeIndex) / Double(prices.count - 1)
        var y = (1 - point) * chartSize.height

        if x > chartSize.width {
            x = chartSize.width
            y = (1 - (prices.last ?? 0)) * chartSize.height
        }

        return CGPoint(x: x, y: y)
    }
    
    // MARK: - Price alerts
    
#if IS_APP
    func checkIfUserEnabledPush() async -> Bool {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        switch status {
        case .authorized:
            return true
        case .notDetermined, .denied, .provisional, .ephemeral:
            return false
        @unknown default:
            return false
        }
    }
#endif
    
    func getPriceAlerts() async {
        if let alerts = await priceAlertsRepository.getAlerts() {
            self.alerts = alerts
                .lazy
                .filter({ $0.coinId == self.cryptoInfo?.id?.lowercased() })
                .sorted(by: { ($0.createdDate.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ) ?? Date()) > ($1.createdDate.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ) ?? Date()) })
            
        } else if self.alerts?.isEmpty ?? true {
            alerts = []
        }
    }
    
    func addPriceAlert(alertCoin: PostAlertCoin) async -> AddPriceAlertResult {
        guard await priceAlertsRepository.ensureFCMToken() else {
            return .fcmTokenUnavailable
        }
        
        if let alerts = await priceAlertsRepository.createPriceAlert(alert: alertCoin) {
            self.alerts = alerts
                .lazy
                .filter({ $0.coinId == self.cryptoInfo?.id?.lowercased() })
                .sorted(by: { ($0.createdDate.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ) ?? Date()) > ($1.createdDate.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ) ?? Date()) })

            return .success
        } else {
            return .failure
        }
    }
    
    func deleteAlert(alert: AlertCoin) async {
        self.alerts = alerts?.filter({ $0.id != alert.id })
        
        if let alerts = await priceAlertsRepository.deleteAlert(alertId: alert.id) {
            self.alerts = alerts
                .lazy
                .filter({ $0.coinId == self.cryptoInfo?.id?.lowercased() })
                .sorted(by: { ($0.createdDate.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ) ?? Date()) > ($1.createdDate.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ) ?? Date()) })
        }
    }
    
    // MARK: - General functions
    
    func stopLivePriceUpdates() async {
        await stopWebSocket()
    }
    
    private func startWebSocket(for coinId: String) async {
        guard isWebSocketEnabled, !coinId.isEmpty else {
            await stopWebSocket()
            return
        }
        
        let connected = await cryptoDetailRepository.connectSignalR { [weak self] update in
            Task { @MainActor [weak self] in
                self?.applyWebSocketUpdate(update)
            }
        }
        
        guard connected else { return }
        
        _ = await cryptoDetailRepository.getCurrency(coinId: coinId)
    }
    
    private func stopWebSocket() async {
        await cryptoDetailRepository.disconnectSignalR()
    }
    
    private func applyWebSocketUpdate(_ update: CGSimplePriceUpdate) {
        guard let coinId = cryptoInfo?.id,
              update.coinId?.lowercased() == coinId.lowercased() else {
            return
        }
        
        let existing = cryptoInfo ?? CurrencyDataModel(id: coinId)
        cryptoInfo = update.apply(to: existing)
        
        guard !candleChartEnabled,
              currentChartType == .price,
              let livePrice = update.price,
              !prices.isEmpty else {
            return
        }
        
        let selectedCurrency = (settingsManager.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code.lowercased()
        guard update.vsCurrency?.lowercased() == selectedCurrency else { return }
        
        prices[prices.count - 1] = livePrice
        
        if !onlyPrices.isEmpty {
            onlyPrices[onlyPrices.count - 1] = livePrice
        }
    }
    
    func shareDetails() {
    #if IS_APP
        // Create snapshot image of share view
        let image = CryptoDetailShareView(viewModel: self)
            .frame(width: 380, height: 370)
            .offset(y: -24)
            .snapshot
        
        guard let iosURL = URL(string: "https://tinyurl.com/ygznuo76"),
              let androidURL = URL(string: "https://tinyurl.com/yz5w8ozj") else { return }
        
        let text = """
        Track \(cryptoInfo?.name ?? "") and other coins in real time with CoinCurrently.
        Download the app for free.
        iOS: \(iosURL)
        Android: \(androidURL)
        """
        
        let activityItemSource = ActivityControllerItemSource(title: "CoinCurrently", text: text)
        let activityViewController = UIActivityViewController(activityItems: [image, activityItemSource], applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { activityType, completed, _, _ in
            let typeKey = activityType?.rawValue ?? "none"
            AnalyticsManager.shared.log(
                AppShareActivityCompleted(
                    fromScreen: .cryptoDetail,
                    activityType: typeKey,
                    completed: completed
                )
            )
        }
        
        if let popover = activityViewController.popoverPresentationController,
           let rootView = UIApplication.shared.window?.rootViewController?.view {
            popover.sourceView = rootView
            popover.sourceRect = CGRect.zero
            popover.permittedArrowDirections = []
        }
        
        UIApplication.shared.window?.rootViewController?.present(activityViewController, animated: true)
    #endif
    }
    
    func updateHoverStats(touches: [CGPoint]) {
        guard !mainReloading else { return }
        guard (!timeStamps.isEmpty || !candleTimestamps.isEmpty) && !touches.isEmpty else {
            isDragging = false
            timer?.invalidate()
            return
        }
        
        if !isDragging {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.isDragging = !touches.isEmpty
                    
                    if self.isDragging {
#if IS_APP
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
                    }
                }
            }
        }
        
        let adjustedTouches = isCandleChartEnabled ? [touches.first ?? .zero] : touches
        
        hoverHelper.offset = adjustedTouches.map {
            CGPoint(x: max(0, min($0.x, chartSize.width.rounded(.down) - 0.00001)), y: $0.y)
        }
        
        if isCandleChartEnabled {
            candleInfoLeftSide = (adjustedTouches.first?.x ?? 0) < chartSize.width / 2
            
            hoverHelper.getHoverPriceCandles(
                readerSize: chartSize,
                offset: hoverHelper.offset.first ?? .zero,
                prices: candleSticks,
                timeChart: selectedTimeFrame,
                isDragging: isDragging,
                volumes: volumes
            )
        } else {
            hoverHelper.getHoverPrice(
                readerSize: chartSize,
                offset: hoverHelper.offset,
                prices: getPrices(),
                dates: getTimestamps(),
                timeChart: selectedTimeFrame,
                isDragging: isDragging
            )
        }
    }
    
    // MARK: - Private main functions
    
    private func setOnlyPrices() {
        let prefix = getPricesRangePrefix(priceVolume: priceVolumeModel)
        
        onlyPrices = priceVolumeModel?.prices?
            .suffix(prefix)
            .compactMap { $0.last ?? 0 } ?? []
    }
    
    private func setPrices() {
        let prefix = getPricesRangePrefix(priceVolume: priceVolumeModel)
        var prices: [[Double?]]?
        
        switch currentChartType {
        case .price:
            prices = priceVolumeModel?.prices
        case .volume:
            prices = priceVolumeModel?.total_volumes
        default:
            prices = priceVolumeModel?.market_caps
        }

        if candleChartEnabled {
            prices = priceVolumeModel?.prices
        }
        
        self.prices = prices?
            .suffix(prefix)
            .compactMap { $0.last ?? 0 }
            .filter { $0 != 0 } ?? []
    }
    
    private func setTimestamps() {
        let prefix = getPricesRangePrefix(priceVolume: priceVolumeModel)
        var timeStamps: [[Double?]]?
        
        switch currentChartType {
        case .price:
            timeStamps = priceVolumeModel?.prices
        case .volume:
            timeStamps = priceVolumeModel?.total_volumes
        default:
            timeStamps = priceVolumeModel?.market_caps
        }

        if candleChartEnabled {
            timeStamps = priceVolumeModel?.prices
        }
        
        self.timeStamps = timeStamps?
            .suffix(prefix)
            .compactMap { $0.first ?? 0 }
            .filter { $0 != 0 } ?? []
    }

    private func setVolumes() {
        let prefix = getPricesRangePrefix(priceVolume: priceVolumeModel)
        
        volumes = priceVolumeModel?.total_volumes?
            .suffix(prefix)
            .compactMap { $0.last ?? 0 }
            .filter { $0 != 0 } ?? []
    }

    private func calculatePoint(
        at index: Int,
        rect: CGSize,
        timestamps: [Double],
        prices: [Double],
        adjustXByHalfPixel: Bool = true
    ) -> CGPoint {
        let normalizedPrices = prices.normalized
        let pointValue = normalizedPrices[safely: index] ?? 0

        let denominator = Double(normalizedPrices.count - 1)
        let x = rect.width * Double(index) / denominator
        let y = (1 - pointValue) * rect.height
        
        return CGPoint(
            x: adjustXByHalfPixel ? x - 0.5 : x,
            y: y.isNaN ? 0.5 * rect.height : y
        )
    }
    
    // MARK: - Private candle functions
    
    private func setCandleSticks() {
        let totalCandles = candleSticksModel?.candle?.count ?? 0
        
        let prefix: Int = {
            switch selectedTimeFrame {
            case .anHour:
                return totalCandles / 24
            default:
                return totalCandles
            }
        }()
        
        candleSticks = candleSticksModel?.candle?.suffix(prefix).compactMap { $0 } ?? []
    }
    
    // MARK: - Private general functions
    
    private func getCandleXPosition(textSize: CGFloat) -> CGFloat {
        let xPoint = candleSticks.map({ $0.open ?? 0 }).point(at: currentCandleHoverIndex, rect: chartSize).x
        return getPriceXPosition(position: xPoint, textSize: textSize, readerWidthSize: chartSize.width)
    }
    
    private func getXPosition(textSize: CGFloat) -> CGFloat {
        let xPoint = getPrices().point(at: currentHoverIndex, rect: chartSize).x
        return getPriceXPosition(position: xPoint, textSize: textSize, readerWidthSize: chartSize.width)
    }
    
    private func getPricesRangePrefix(priceVolume: PriceVolumeModel?) -> Int {
        let count = priceVolume?.prices?.count ?? 0
        
        switch selectedTimeFrame {
        case .anHour:
            return count / 24
        default:
            return count
        }
    }
}
