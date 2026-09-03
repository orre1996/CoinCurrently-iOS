//
//  TrackerViewModel.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-23.
//

import Foundation
import SwiftUI

@MainActor
protocol CryptoDetailViewModel: ChartHoverHosting {
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
    var isGraphLinear: Bool { get set }
    var currentChartType: ChartTypes { get set }
    var candleChartEnabled: Bool { get set }
    var currentDays: String { get set }
    var selectedTimeFrame: TimeCharts { get set }
    var selectedSortOption: SortOption { get set }
    var exchangeMarketItems: [ExchangeMarketItem]? { get set }
    var isWebSocketEnabled: Bool { get }
    func setNewSortOption(newSortOption: SortOption) async
    
    var changePercent: Double? { get }
    var mainGraphStats: [String?] { get }
    var isCandleChartEnabled: Bool { get }
    var candlePrices: [Double] { get }
    var highestCandleValue: Double? { get }
    var lowestCandleValue: Double? { get }
    var candleTimestamps: [Double] { get }
    var candleMiddlePrices: [Double] { get }
    var graphColor: Color { get }
    var hoverTimePosition: CGFloat { get }
    var hoverPricePosition: CGFloat { get }
    var hoverCandleTimePosition: CGFloat { get }
    var mainDragIndex: [Int] { get }
    var dragPositions: [CGPoint] { get }
    var pointCandle: CGPoint { get }

    func setStartData() async
    func point(at index: Int, rect: CGSize) -> CGPoint
    func getGlobalMarketData() async
    func hasBoughtPro() async -> Bool
    
    func refresh(showReload: Bool, newDays: String?, newTimeChart: TimeCharts?, forceId: String?) async
    func toggleChart() async
    func getMainCryptoInfo(id: String?) async
    func getMainCurrencyPrices(id: String?, chart: TimeCharts) async
    func newMainCoin(id: String) async
    func handleFavoriteButtonPressed() async
    func setChartType(type: ChartTypes)
    func getPrices() -> [Double]
    func getTimestamps() -> [Double]
    func getPriceInChart(prices: [Double], at index: Int) -> String?
    func getCandleChart(id: String?, days: String) async
    func getPriceCandleInChart(at index: Int) -> String?
    func shareDetails()
    func updateHoverStats(touches: [CGPoint])
    func stopLivePriceUpdates() async
}

@MainActor @Observable
final class CryptoDetailViewModelImp: CryptoDetailViewModel, ChartHoverHosting {
    
    private let cryptoDetailRepository: CryptoDetailRepository
    private let toplistRepository: ToplistRepository
    private let globalMarketRepository: GlobalMarketRepository
    private let storageManager: CachedStorageManager
    private let storeKitManager: StoreKitManager
    private let analyticsManager: AnalyticsManager
    private let settingsManager: SettingsManager
    
    var hover = ChartHoverState()
    
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
    
    // General
    var isGraphLinear: Bool = SettingsManager.shared.get(key: AppSettingKey.isGraphLinear) ?? true
    var currentChartType: ChartTypes = SettingsManager.shared.get(key: AppSettingKey.graphType) ?? .price
    var candleChartEnabled = SettingsManager.shared.getCandleChartSelected()
    var currentDays = TimeCharts.getStartTimeFrame(between: .anHour, and: .max).days
    var selectedTimeFrame = TimeCharts.getStartTimeFrame(between: .anHour, and: .max)

    var selectedSortOption: SortOption = .volumeDesc
    var exchangeMarketItems: [ExchangeMarketItem]? = nil
    
    private(set) var hasProSubscription = false
    
    var isWebSocketEnabled: Bool {
        settingsManager.isWebSocketEnabled(hasPro: hasProSubscription)
    }
    
    init(
        cryptoInfo: CurrencyDataModel,
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        globalMarketRepository: GlobalMarketRepository = GlobalMarketRepositoryImp.shared,
        storageManager: CachedStorageManager = CachedStorageManagerImp.shared,
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared,
        analyticsManager: AnalyticsManager = AnalyticsManager.shared,
        settingsManager: SettingsManager = SettingsManager.shared
    ) {
        self.cryptoDetailRepository = cryptoDetailRepository
        self.toplistRepository = toplistRepository
        self.globalMarketRepository = globalMarketRepository
        self.storageManager = storageManager
        self.storeKitManager = storeKitManager
        self.analyticsManager = analyticsManager
        self.settingsManager = settingsManager
        
        self.cryptoInfo = cryptoInfo
    }
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await toplistRepository.ensureCacheLoaded()
        
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
        
        if let globalData = await globalMarketRepository.cachedGlobalMarket?.data {
            globalMarketData = globalData
        }
        
        inFavoritesList = await toplistRepository.cachedFavorites?.data.contains { $0.id == cryptoInfo?.id } ?? false

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

    var differenceValue: String { hover.differenceValue }
    
    var differencePercent: String { hover.differencePercent }
    
    var graphColor: Color {
        hover.graphColor(idle: changePercent?.changeColor ?? .onSurfaceDim)
    }
    
    var hoverTime: String { hover.hoverTime }
    
    var hoverPrice: String { hover.hoverPrice }
    
    var hoverTimePosition: CGFloat {
        hover.timeLabelX(prices: getPrices())
    }
    
    var hoverPricePosition: CGFloat {
        hover.priceLabelX(prices: getPrices())
    }

    var hoverCandleTimePosition: CGFloat {
        let pointX = candleSticks.map({ $0.open ?? 0 }).point(at: currentCandleHoverIndex, rect: chartSize).x
        return hover.timeLabelX(pointX: pointX)
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

    private var currentCandleHoverIndex: Int {
        guard chartSize.width > 0 else { return 0 }
        let hoverPoint = hoverHelper.offset.map { $0.x }.first ?? 0
        return candleBinIndex(x: hoverPoint, width: chartSize.width, candleCount: candleSticks.count)
    }
    
    // MARK: - Download data functions

    func getGlobalMarketData() async {
        if let globalMarketData = await globalMarketRepository.getGlobalMarket() {
            self.globalMarketData = globalMarketData
        }
    }
    
    func refresh(
        showReload: Bool = true,
        newDays: String? = nil,
        newTimeChart: TimeCharts? = nil,
        forceId: String? = nil
    ) async {
        mainReloading = showReload
        
        hasProSubscription = await storeKitManager.currentSubscription != nil
        
        let days = newDays ?? self.currentDays
        let chart = newTimeChart ?? self.selectedTimeFrame
        let mainId = forceId ?? self.cryptoInfo?.id
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.getMainCryptoInfo(id: mainId) }
            
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
        guard hover.applyTouches(
            touches,
            canUpdate: !mainReloading,
            hasSeries: !timeStamps.isEmpty || !candleTimestamps.isEmpty,
            limitToFirstTouch: isCandleChartEnabled
        ) else {
            return
        }
        
        if isCandleChartEnabled {
            candleInfoLeftSide = (hoverHelper.offset.first?.x ?? 0) < chartSize.width / 2
            
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
