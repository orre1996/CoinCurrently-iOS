//
//  ExchangeViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-05-26.
//

import SwiftUI
import Combine

@MainActor
protocol ExchangeDetailViewModel: ChartHoverHosting {
    var exchangeVolume: [ExchangePriceModel]? { get set }
    var exchangeInfo: Exchange { get set }
    var bitcoin: CurrencyDataModel? { get set }
    var toplist: [Toplist]? { get set }
    var news: [NewsItem] { get set }
    var showNewsError: Bool { get set }
    var reloading: Bool { get set }
    var showMainPriceError: Bool { get set }
    var timeChart: TimeCharts { get set }
    var currentDays: String { get set }
    var selectedTimeFrame: TimeCharts { get set }
    var currentChartType: ChartTypes { get set }
    var prices: [Double] { get set }
    var timeStamps: [Double] { get set }
    var days: String { get set }
    var mainGraphStats: [String?] { get }
    var changePercent: Double? { get }
    var graphColor: Color { get }
    var hoverTimePosition: CGFloat { get }
    var hoverPricePosition: CGFloat { get }
    var mainDragIndex: [Int] { get }
    var dragPositions: [CGPoint] { get }
    var selectedSortOption: SortOption { get set }

    func setStartData() async
    func getPriceInChart(prices: [Double], at index: Int) -> String?
    func point(at index: Int, rect: CGSize) -> CGPoint
    func getExchangeData(id: String?) async
    func getExchangePrices(id: String?, days: String) async
    func getBitcoin() async
    func getNews() async
    func refresh(newDays: String?, newTimeChart: TimeCharts?, forceId: String?, getNews: Bool) async
    func getPrices() -> [Double]
    func setPrices()
    func getTimestamps() -> [Double]
    func setTimestamps()
    func getChartValues() -> [String]
    func getOpenPrice() -> Double
    func getPercentageChange() -> Double?
    func getHighestPrice() -> Double
    func getLowestPrice() -> Double
    func isAllLinksEmpty() -> Bool
    func getTelegramUrl(link: String) -> String
    func getRedditUrl() -> String
    func getFacebookUrl() -> String
    func updateHoverStats(touches: [CGPoint])
    func setNewSortOption(newSortOption: SortOption) async
    var exchangeMarketItems: [ExchangeMarketItem]? { get set }
}

@MainActor @Observable
final class ExchangeDetailViewModelImp: ExchangeDetailViewModel, ChartHoverHosting {
    var exchangeVolume: [ExchangePriceModel]?
    var exchangeInfo: Exchange
    var bitcoin: CurrencyDataModel?
    var news = [NewsItem]()
    var showNewsError = false
    var reloading = true
    var showMainPriceError = false
    var timeChart = TimeCharts.getStartTimeFrame(between: .aDay, and: .aYear)
    var currentDays = TimeCharts.getStartTimeFrame(between: .aDay, and: .aYear).days
    var selectedTimeFrame = TimeCharts.getStartTimeFrame(between: .aDay, and: .aYear)
    
    var currentChartType: ChartTypes = SettingsManager.shared.get(key: AppSettingKey.graphType) ?? .price

    var hover = ChartHoverState()
    
    var prices = [Double]()
    var timeStamps = [Double]()

    var days = TimeCharts.getStartTimeFrame(between: .aDay, and: .aYear).days
    
    var selectedSortOption: SortOption = .volumeDesc
    var exchangeMarketItems: [ExchangeMarketItem]? = nil
    
    private let exchangeDetailsRepository: ExchangeDetailsRepository
    private let storageManager: CachedStorageManager
    private let cryptoDetailRepository: CryptoDetailRepository
    private let newsRepository: NewsRepository
    private let toplistRepository: ToplistRepository

    var toplist: [Toplist]?

    init(
        exchangeDetail: Exchange,
        exchangeDetailsRepository: ExchangeDetailsRepository = ExchangeDetailsRepositoryImp.shared,
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared,
        newsRepository: NewsRepository = NewsRepositoryImp.shared,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        storageManager: CachedStorageManager = CachedStorageManagerImp.shared
    ) {
        self.exchangeDetailsRepository = exchangeDetailsRepository
        self.cryptoDetailRepository = cryptoDetailRepository
        self.newsRepository = newsRepository
        self.toplistRepository = toplistRepository
        self.storageManager = storageManager
        
        self.exchangeInfo = exchangeDetail
    }
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await exchangeDetailsRepository.ensureCacheLoaded()
        await toplistRepository.ensureCacheLoaded()

        let id = self.exchangeInfo.id ?? ""
        if !id.isEmpty {
            await exchangeDetailsRepository.loadCachedDataForExchange(id: id, days: days)
        }

        if let toplist = await toplistRepository.cachedToplist[SortOption.mktCapDesc.toplistApiValue]?.data, !toplist.isEmpty {
            self.toplist = toplist.sorted(by: { $0.market_cap_rank ?? 9999 < $1.market_cap_rank ?? 9999 })
        }

        selectedSortOption = await storageManager.load(type: AppSettingKey.exchangeDetailSortOption.rawValue) ?? .volumeDesc

        let data = await exchangeDetailsRepository.cachedExchangeDetail[id]?.data.copy(withId: id)

        self.exchangeInfo = data ?? exchangeInfo
        updateExchangeMarketItems()

        if let prices = await exchangeDetailsRepository.cachedExchangePrices["\(id)-\(days)"]?.data {
            self.exchangeVolume = prices
        }
        
        if let bitcoin = await cryptoDetailRepository.cachedBitcoin?.data {
            self.bitcoin = bitcoin
        }

        let newsId = String(exchangeInfo.name?.split(separator: " ").first ?? "")
        
        if let news = await newsRepository.cachedNews[.exchange(id: newsId)] {
            self.news = news.data.data
        }

        selectedSortOption = await storageManager.load(type: AppSettingKey.exchangeDetailSortOption.rawValue) ?? .volumeDesc
    }

    func setNewSortOption(newSortOption: SortOption) async {
        selectedSortOption = newSortOption
        await storageManager.save(type: AppSettingKey.exchangeDetailSortOption.rawValue, data: selectedSortOption)
        updateExchangeMarketItems()
    }

    func getToplist() async {
        if let toplist = await toplistRepository.getMarketToplist(
            sortOption: .mktCapDesc,
            priceChange: .sevenDays,
            platformId: nil
        ) {
            self.toplist = toplist
        }
    }
    
    var mainGraphStats: [String?] {
        return (0..<6).map({ getPriceInChart(prices: getPrices(), at: $0) })
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
    
    var changePercent: Double? {
        guard let first = getPrices().first,
              let last = getPrices().last else {
            return nil
        }
        
        return Double.getDifferenceInPercent(between: last, and: first)?.roundTo(places: 7)
    }
    
    var graphColor: Color {
        hover.graphColor(idle: changePercent?.changeColor ?? .onSurfaceDim)
    }
    
    var hoverTimePosition: CGFloat {
        hover.timeLabelX(prices: getPrices())
    }
    
    var hoverPricePosition: CGFloat {
        hover.priceLabelX(prices: getPrices())
    }

    var mainDragIndex: [Int] {
        hover.linearDragIndices(priceCount: getPrices().count, timestamps: getTimestamps())
    }
    
    var dragPositions: [CGPoint] {
        hover.linearDragPositions(priceCount: getPrices().count, timestamps: getTimestamps()) { index, size in
            point(at: index, rect: size)
        }
    }

    func point(at index: Int, rect: CGSize) -> CGPoint {
        return calculatePoint(
            at: index,
            rect: rect,
            timestamps: getTimestamps(),
            prices: getPrices()
        )
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
    
    func getExchangeData(id: String?) async {
        if let exchangeInfo = await exchangeDetailsRepository.getExchangeDetails(id: id) {
            self.exchangeInfo = exchangeInfo
            updateExchangeMarketItems()
        }
    }

    private func updateExchangeMarketItems() {
        guard let tickers = exchangeInfo.tickers else {
            exchangeMarketItems = nil
            return
        }
        let items = tickers.map { ExchangeMarketItem.from($0, toplist: toplist) }
        exchangeMarketItems = items.sorted(by: selectedSortOption)
    }
    
    func getExchangePrices(
        id: String?,
        days: String
    ) async {
        exchangeVolume = await exchangeDetailsRepository.getExchangePrices(
            id: id,
            days: days
        )

        showMainPriceError = exchangeVolume == nil
    }

    func getBitcoin() async {
        if let bitcoin = await cryptoDetailRepository.getBitcoin() {
            self.bitcoin = bitcoin
        }
    }

    func getNews() async {
        showNewsError = false

        let id = String(exchangeInfo.name?.split(separator: " ").first ?? "")

        if let news = await newsRepository.getNews(type: .exchange(id: id), count: 25), !news.isEmpty {
            self.news = news
        } else {
            showNewsError = true
        }
    }
    
    func refresh(
        newDays: String? = nil,
        newTimeChart: TimeCharts? = nil,
        forceId: String? = nil,
        getNews: Bool = true,
    ) async {
        reloading = true
        
        let days = newDays ?? self.currentDays
        let chart = newTimeChart ?? self.selectedTimeFrame
        let id = forceId ?? self.exchangeInfo.id
        
        await withTaskGroup(of: Void.self) { group in
            if getNews {
                group.addTask { await self.getNews() }
            }

            group.addTask { await self.getExchangeData(id: id) }
            group.addTask { await self.getExchangePrices(id: id, days: days) }
            group.addTask { await self.getBitcoin() }
            group.addTask { await self.getToplist() }
        }
        
        currentDays = days
        selectedTimeFrame = chart
        
        setPrices()
        setTimestamps()
        
        reloading = false
    }

    func getPrices() -> [Double] {
        return prices
    }
    
    func setPrices() {
        self.prices = exchangeVolume?.map {
            ($0.price ?? 0) * (bitcoin?.market_data?.current_price?.getConvertedCurrency() ?? 0.0)
        } ?? []
    }
    
    func getTimestamps() -> [Double] {
        return timeStamps
    }
    
    func setTimestamps() {
        self.timeStamps = exchangeVolume?.compactMap({ $0.timestamp }) ?? []
    }

    func getChartValues() -> [String] {
        var priceArray = [String]()

        let prices = getPrices()
        let pricesCount = prices.count

        if pricesCount == 0 { return [] }

        let steps: Double = 1/8

        priceArray = (1..<6).map({
            let price = Double(prices[safely: Int(Double(pricesCount) * steps * Double($0))] ?? 0).formatCurrency(currency: SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel(), accessible: true)

            return "The volume was \(price) on"
        })

        return priceArray
    }

    func getOpenPrice() -> Double {
        return (exchangeVolume?.first?.price ?? 0.0) * (bitcoin?.market_data?.current_price?.getConvertedCurrency() ?? 0.0)
    }
    
    func getPercentageChange() -> Double? {
        let temp = (exchangeVolume?.last?.price ?? 0.0) - (exchangeVolume?.first?.price ?? 0.0)
        let percentChange = (100 * (temp / (exchangeVolume?.first?.price ?? 0.0)))
        
        if exchangeVolume?.first?.price ?? 0.0 == 0 {
            return 0.0
        }
        
        return percentChange
    }
    
    func getHighestPrice() -> Double {
        return (exchangeVolume?.max(by: { ($0.price ?? 0) > ($1.price ?? 0) })?.price ?? 0.0) * (bitcoin?.market_data?.current_price?.getConvertedCurrency() ?? 0.0)
    }
    
    func getLowestPrice() -> Double {
        return (exchangeVolume?.min(by: { ($0.price ?? 0) < ($1.price ?? 0) })?.price ?? 0.0) * (bitcoin?.market_data?.current_price?.getConvertedCurrency() ?? 0.0)
    }
    
    
    func isAllLinksEmpty() -> Bool {
        return (exchangeInfo.url?.isEmpty ?? true) &&
        (exchangeInfo.facebook_url?.isEmpty ?? true) &&
        (exchangeInfo.reddit_url?.isEmpty ?? true) &&
        (exchangeInfo.telegram_url?.isEmpty ?? true) &&
        (exchangeInfo.slack_url?.isEmpty ?? true) &&
        (exchangeInfo.other_url_1?.isEmpty ?? true) &&
        (exchangeInfo.other_url_2?.isEmpty ?? true)
    }
    
    func getTelegramUrl(link: String) -> String {
        var url = link
        if !url.contains("https://www.") {
            url = "https://www.t.me/\(url)"
        }
        
        return url
    }
    
    func getRedditUrl() -> String {
        var url = exchangeInfo.reddit_url ?? ""
        if !url.contains("https://www.") {
            url = "https://www.reddit.com\(url)"
        }
        
        return url
    }
    
    func getFacebookUrl() -> String {
        var url = exchangeInfo.facebook_url ?? ""
        if !url.contains("https://www.") {
            url = "https://www.facebook.com/\(url)"
        }
        
        return url
    }
    
    func updateHoverStats(touches: [CGPoint]) {
        hover.updateLinear(
            touches: touches,
            prices: getPrices(),
            dates: getTimestamps(),
            timeChart: selectedTimeFrame,
            canUpdate: !reloading
        )
    }
}
