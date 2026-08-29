//
//  CompareCoinViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 8/20/25.
//

import SwiftUI

@MainActor
protocol CompareCoinsViewModel {
    var cryptoInfo: CurrencyDataModel? { get set }
    var priceVolumeModel: PriceVolumeModel? { get set }
    var prices: [Double] { get set }
    var onlyPrices: [Double] { get set }
    var volumes: [Double] { get set }
    var timeStamps: [Double] { get set }
    var mainReloading: Bool { get set }
    var showMainPriceError: Bool { get set }
    var comparedCryptoInfo: CurrencyDataModel? { get set }
    var comparedPriceVolumeModel: PriceVolumeModel? { get set }
    var comparePrices: [Double] { get set }
    var onlyComparePrices: [Double] { get set }
    var compareVolumes: [Double] { get set }
    var compareTimeStamps: [Double] { get set }
    var compareReloading: Bool { get set }
    var showComparePriceError: Bool { get set }
    var hoverHelper: HoverHelper { get set }
    var hoverPriceWidthSize: CGFloat { get set }
    var hoverComparePriceWidthSize: CGFloat { get set }
    var hoverTimeWidthSize: CGFloat { get set }
    var chartSize: CGSize { get set }
    var selectedTimeFrame: TimeCharts { get set }
    var currentChartType: ChartTypes { get set }
    var currentDays: String { get set }
    var isDragging: Bool { get set }
    var comparableCoins: [Toplist] { get set }
    var dragIndex: Int { get }
    var dragPositions: CGPoint { get }
    var compareDragPositions: CGPoint { get }
    var chartValues: [String] { get }
    var graphStats: [String?] { get }
    var hoverTime: String { get }
    var hoverPrice: String { get }
    var compareHoverPrice: String { get }
    var hoverTimePosition: CGFloat { get }
    
    var mainDifferencePercent: Double { get }
    var compareDifferencePercent: Double { get }
    
    var isWebSocketEnabled: Bool { get }
    
    func setStartData() async
    func getToplist() async
    func refresh(newDays: String?, newTimeChart: TimeCharts?, forceMainId: String?, forceCompareId: String?) async
    func setChartType(type: ChartTypes)
    func getMainCryptoInfo(id: String?) async
    func getCurrencyPrices(mainId: String?, compareId: String?, chart: TimeCharts) async
    func getPrices(dropLastTwo: Bool) -> [Double]
    func getTimestamps(dropLastTwo: Bool) -> [Double]
    func getCompareCryptoInfo(id: String?) async
    func getCompareCurrencyPrices(id: String?, chart: TimeCharts) async
    func getComparePrices(dropLastTwo: Bool) -> [Double]
    func getCompareTimestamps(dropLastTwo: Bool) -> [Double]
    func updateHoverStats(touches: [CGPoint])
    func point(at index: Int, rect: CGSize, prices: [Double]) -> CGPoint
    func stopLivePriceUpdates() async
    func syncLivePriceUpdates() async
}

@MainActor @Observable
final class CompareCoinsViewModelImp: CompareCoinsViewModel {
    private let cryptoDetailRepository: CryptoDetailRepository
    private let toplistRepository: ToplistRepository
    private let settingsManager: SettingsManager
    private let storeKitManager: StoreKitManager
    
    // Main coin
    var cryptoInfo: CurrencyDataModel?
    var priceVolumeModel: PriceVolumeModel?
    
    var prices = [Double]()
    var onlyPrices = [Double]()
    var volumes = [Double]()
    var timeStamps = [Double]()
    
    var mainReloading = true
    var showMainPriceError = false
    
    // Compare coin
    var comparedCryptoInfo: CurrencyDataModel?
    var comparedPriceVolumeModel: PriceVolumeModel?
    
    var comparePrices = [Double]()
    var onlyComparePrices = [Double]()
    var compareVolumes = [Double]()
    var compareTimeStamps = [Double]()
    
    var compareReloading = false
    var showComparePriceError = false
    
    // Hover
    var hoverHelper = HoverHelper()
    
    var hoverPriceWidthSize: CGFloat = 0
    var hoverComparePriceWidthSize: CGFloat = 0
    var hoverTimeWidthSize: CGFloat = 0
    var chartSize: CGSize = .zero
    
    // General
    
    var selectedTimeFrame = TimeCharts.getStartTimeFrame(between: .anHour, and: .max)
    var currentChartType: ChartTypes = SettingsManager.shared.get(key: AppSettingKey.graphType) ?? .price
    var currentDays = TimeCharts.getStartTimeFrame(between: .anHour, and: .max).days
    
    var isDragging = false
    
    var comparableCoins = [Toplist]()
    
    private var timer: Timer?
    
    private(set) var hasProSubscription = false
    
    var isWebSocketEnabled: Bool {
        settingsManager.isWebSocketEnabled(hasPro: hasProSubscription)
    }
    
    init(
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        settingsManager: SettingsManager = SettingsManager.shared,
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared,
        cryptoInfo: CurrencyDataModel?,
        priceVolumeModel: PriceVolumeModel?,
        compareId: String
    ) {
        self.cryptoDetailRepository = cryptoDetailRepository
        self.toplistRepository = toplistRepository
        self.settingsManager = settingsManager
        self.storeKitManager = storeKitManager
        self.cryptoInfo = cryptoInfo
        self.priceVolumeModel = priceVolumeModel
        self.comparedCryptoInfo = CurrencyDataModel(id: compareId)
    }
    
    var dragIndex: Int {
        let pts = getPrices(dropLastTwo: true)
        let offsetPoint = hoverHelper.offset.first ?? .zero
        guard chartSize.width > 0, !pts.isEmpty else { return -1 }
        return chartLinearSeriesIndex(x: offsetPoint.x, width: chartSize.width, pointCount: pts.count)
    }
    
    var dragPositions: CGPoint {
        return point(
            at: dragIndex,
            rect: CGSize(width: chartSize.width, height: chartSize.height),
            prices: getPrices()
        )
    }
    
    var compareDragPositions: CGPoint {
        return point(
            at: dragIndex,
            rect: CGSize(width: chartSize.width, height: chartSize.height),
            prices: getComparePrices()
        )
    }
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await toplistRepository.ensureCacheLoaded()
        
        hasProSubscription = await storeKitManager.currentSubscription != nil
        
        if let priceData = await cryptoDetailRepository.cachedCryptoPrices["\(cryptoInfo?.id ?? "")-\(currentDays)-compare"]?.data {
            self.priceVolumeModel = priceData
            
            setPrices()
            setOnlyPrices()
            setVolumes()
            setTimestamps()
        }
        
        if let priceData = await cryptoDetailRepository.cachedCryptoPrices["\(comparedCryptoInfo?.id ?? "")-\(currentDays)-compare"]?.data {
            self.comparedPriceVolumeModel = priceData

            setComparePrices()
            setOnlyComparePrices()
            setComparedVolumes()
            setCompareTimestamps()
        }
        
        addExtraElementsToTimeline()
        
        let coins: [Toplist] = await {
            if let mainToplist = await toplistRepository.cachedToplist[SortOption.mktCapDesc.toplistApiValue]?.data {
                return mainToplist
            }
            
            return await toplistRepository.cachedSmallToplist?.data ?? []
        }()
        
        comparableCoins = coins.sorted {
            ($0.market_cap_rank ?? Int.max) < ($1.market_cap_rank ?? Int.max)
        }
    }
    
    // MARK: - Download data functions
    
    func getToplist() async {
        if let toplist = await toplistRepository.getMarketToplist(
            sortOption: .mktCapDesc,
            priceChange: .sevenDays,
            platformId: nil
        ) {
            self.comparableCoins = toplist
        }
    }
    
    func refresh(
        newDays: String? = nil,
        newTimeChart: TimeCharts? = nil,
        forceMainId: String? = nil,
        forceCompareId: String? = nil,
    ) async {
        mainReloading = true
        compareReloading = true
        showComparePriceError = false
        
        hasProSubscription = await storeKitManager.currentSubscription != nil
        
        let days = newDays ?? self.currentDays
        let chart = newTimeChart ?? self.selectedTimeFrame
        let mainId = forceMainId ?? self.cryptoInfo?.id
        let compareId = forceCompareId ?? self.comparedCryptoInfo?.id
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.getMainCryptoInfo(id: mainId) }
            group.addTask { await self.getCompareCryptoInfo(id: compareId) }
            group.addTask { await self.getCurrencyPrices(mainId: mainId, compareId: compareId, chart: chart) }
        }
        
        currentDays = days
        selectedTimeFrame = chart
        
        addExtraElementsToTimeline()
        
        mainReloading = false
        compareReloading = false
        
        await startWebSocket(mainId: mainId, compareId: compareId)
    }
    
    var chartValues: [String] {
        let currency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        let steps: Double = 1 / 6
        
        let prices = getPrices()
        let comparePrices = getComparePrices()
        
        guard !prices.isEmpty, !comparePrices.isEmpty else {
            return []
        }
        
        let chartLabel: String
        switch currentChartType {
        case .price: 
            chartLabel = "price"
        case .volume:
            chartLabel = "volume"
        case .mktCap:
            chartLabel = "market cap"
        }
        
        return (1..<5).map { step in
            let i = Int(Double(prices.count) * steps * Double(step))
            let j = Int(Double(comparePrices.count) * steps * Double(step))
            
            let price = prices[safely: i]?.formatCurrency(currency: currency, accessible: true) ?? ""
            let comparePrice = comparePrices[safely: j]?.formatCurrency(currency: currency, accessible: true) ?? ""
            
            let name = cryptoInfo?.name ?? ""
            let compareName = comparedCryptoInfo?.name ?? ""
            
            return "The \(chartLabel) was \(price) for \(name) and \(comparePrice) for \(compareName) on"
        }
    }
    
    var mainDifferencePercent: Double {
        let first = prices.first(where: { $0 != -1 }) ?? 0
        let second = hoverHelper.hoverPrices[safely: 0] ?? 0.0
        let difference = Double.getDifferenceInPercent(between: second, and: first) ?? 0
        
        return difference
    }
    
    var compareDifferencePercent: Double {
        let first = comparePrices.first(where: { $0 != -1 }) ?? 0
        let second = hoverHelper.compareHoverPrice
        let difference = Double.getDifferenceInPercent(between: second, and: first) ?? 0
        
        return difference
    }

    // MARK: - Private main functions
    
    private func setOnlyPrices() {
        let prefix = getPricesRangePrefix(priceVolume: priceVolumeModel)
        
        onlyPrices = priceVolumeModel?.prices?
            .suffix(prefix)
            .compactMap { $0.last ?? 0 }
            .filter { $0 != 0 } ?? []
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
    
    // MARK: - Private compare functions
    
    private func setOnlyComparePrices() {
        let prefix = getPricesRangePrefix(priceVolume: comparedPriceVolumeModel)
        
        onlyComparePrices = comparedPriceVolumeModel?.prices?
            .suffix(prefix)
            .compactMap { $0.last ?? 0 }
            .filter { $0 != 0 } ?? []
    }
    
    private func setComparePrices() {
        let prefix = getPricesRangePrefix(priceVolume: comparedPriceVolumeModel)
        var prices: [[Double?]]?
        
        switch currentChartType {
        case .price:
            prices = comparedPriceVolumeModel?.prices
        case .volume:
            prices = comparedPriceVolumeModel?.total_volumes
        default:
            prices = comparedPriceVolumeModel?.market_caps
        }
        
        self.comparePrices = prices?
            .suffix(prefix)
            .compactMap { $0.last ?? 0 }
            .filter { $0 != 0 } ?? []
    }
    
    private func setCompareTimestamps() {
        let prefix = getPricesRangePrefix(priceVolume: comparedPriceVolumeModel)
        var timeStamps: [[Double?]]?
        
        switch currentChartType {
        case .price:
            timeStamps = comparedPriceVolumeModel?.prices
        case .volume:
            timeStamps = comparedPriceVolumeModel?.total_volumes
        default:
            timeStamps = comparedPriceVolumeModel?.market_caps
        }
        
        self.compareTimeStamps = timeStamps?
            .suffix(prefix)
            .compactMap { $0.first ?? 0 }
            .filter { $0 != 0 } ?? []
    }
    
    private func setComparedVolumes() {
        let prefix = getPricesRangePrefix(priceVolume: comparedPriceVolumeModel)
        
        compareVolumes = comparedPriceVolumeModel?.total_volumes?
            .suffix(prefix)
            .compactMap { $0.last ?? 0 }
            .filter { $0 != 0 } ?? []
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
    
    private func addExtraElementsToTimeline() {
        guard priceVolumeModel != nil, comparedPriceVolumeModel != nil else { return }
        
        setPrices()
        setOnlyPrices()
        setVolumes()
        setTimestamps()
        
        setComparePrices()
        setOnlyComparePrices()
        setComparedVolumes()
        setCompareTimestamps()
        
        let firstMain = prices.first ?? 0
        let mainMax = prices.max() ?? 0
        let mainMin = prices.min() ?? 0
        let firstTimestamp = timeStamps.first ?? 0
        
        let firstCompare = comparePrices.first ?? 0
        let compareMax = comparePrices.max() ?? 0
        let compareMin = comparePrices.min() ?? 0
        let compareTimestamps = compareTimeStamps.first ?? 0
        
        let compareMaxPercent = Double.getDifferenceInDecimal(between: compareMax, and: firstCompare) ?? 0
        let compareMinPercent = Double.getDifferenceInDecimal(between: compareMin, and: firstCompare) ?? 0
        
        prices.append(contentsOf: [firstMain * compareMaxPercent, firstMain * compareMinPercent])
        
        let mainDate = Date(timeIntervalSince1970: TimeInterval((timeStamps.first ?? 0) / 1000))
        let compareDate = Date(timeIntervalSince1970: TimeInterval((compareTimeStamps.first ?? 0) / 1000))
        
        if abs(mainDate.timeIntervalSince(compareDate)) > Date.moreThanADay {
            timeStamps.append(contentsOf: [compareTimestamps, compareTimestamps])
        } else {
            timeStamps.append(contentsOf: [firstTimestamp, firstTimestamp])
        }
        
        let mainMaxPercent = Double.getDifferenceInDecimal(between: mainMax, and: firstMain) ?? 0
        let mainMinPercent = Double.getDifferenceInDecimal(between: mainMin, and: firstMain) ?? 0
        
        comparePrices.append(contentsOf: [firstCompare * mainMaxPercent, firstCompare * mainMinPercent])
        
        if abs(compareDate.timeIntervalSince(mainDate)) > Date.moreThanADay {
            compareTimeStamps.append(contentsOf: [firstTimestamp, firstTimestamp])
        } else {
            compareTimeStamps.append(contentsOf: [compareTimestamps, compareTimestamps])
        }
        
        let delta = abs(prices.count - comparePrices.count)
        if prices.count > comparePrices.count {
            comparePrices.insert(contentsOf: Array(repeating: -1, count: delta), at: 0)
            compareTimeStamps.insert(contentsOf: Array(repeating: -1, count: delta), at: 0)
            compareVolumes.insert(contentsOf: Array(repeating: -1, count: delta), at: 0)
        } else if comparePrices.count > prices.count {
            prices.insert(contentsOf: Array(repeating: -1, count: delta), at: 0)
            timeStamps.insert(contentsOf: Array(repeating: -1, count: delta), at: 0)
            volumes.insert(contentsOf: Array(repeating: -1, count: delta), at: 0)
        }
    }
    
    func setChartType(type: ChartTypes) {
        currentChartType = type
        SettingsManager.shared.set(data: currentChartType, key: AppSettingKey.graphType)
        
        addExtraElementsToTimeline()
    }
    
    var graphStats: [String?] {
        let mainPrices = getPrices(dropLastTwo: true).filter { $0 != -1 }
        let comparePrices = getComparePrices(dropLastTwo: true).filter { $0 != -1 }
        
        guard let firstMainPrice = mainPrices.first,
              let maxMainPrice = mainPrices.max(),
              let minMainPrice = mainPrices.min(),
              let firstComparePrice = comparePrices.first,
              let maxComparePrice = comparePrices.max(),
              let minComparePrice = comparePrices.min()
        else {
            return (0..<6).map({ _ in nil })
        }
        
        let mainTopPercent = Double.getDifferenceInPercent(between: maxMainPrice, and: firstMainPrice) ?? 0
        let mainBottomPercent = Double.getDifferenceInPercent(between: minMainPrice, and: firstMainPrice) ?? 0
        
        let compareTopPercent = Double.getDifferenceInPercent(between: maxComparePrice, and: firstComparePrice) ?? 0
        let compareBottomPercent = Double.getDifferenceInPercent(between: minComparePrice, and: firstComparePrice) ?? 0
        
        let chartMax = max(mainTopPercent, compareTopPercent)
        let chartMin = min(mainBottomPercent, compareBottomPercent)
        
        let step = (chartMax - chartMin) / 5
        
        return (0..<6).map({
            let change = chartMin + (step * Double($0))
            return "\(change.formatted(.number.precision(.fractionLength(2))))%"
        })
    }
    
    var hoverTime: String {
        return hoverHelper.hoverTimes.first ?? "0"
    }
    
    var hoverPrice: String {
        return getPrices(dropLastTwo: true)[safely: dragIndex] == -1 ? "N/A" : hoverHelper.hoverPrices.first?.formatCurrency(threshold: FormattingThreshold.million) ?? "0"
    }
    
    var compareHoverPrice: String {
        return getComparePrices(dropLastTwo: true)[safely: dragIndex] == -1 ? "N/A" : hoverHelper.compareHoverPrice.formatCurrency(threshold: FormattingThreshold.million)
    }
    
    var hoverTimePosition: CGFloat {
        return getXPosition(textSize: hoverTimeWidthSize) - hoverTimeWidthSize / 2
    }
    
    private func getXPosition(textSize: CGFloat) -> CGFloat {
        let xPoint = point(at: currentHoverIndex, rect: chartSize, prices: getPrices()).x
        return getPriceXPosition(position: xPoint, textSize: textSize, readerWidthSize: chartSize.width)
    }
    
    private var currentHoverIndex: Int {
        guard chartSize.width > 0 else { return 0 }
        
        let hoverPoints = hoverHelper.offset.map { $0.x }
        let hoverPoint: CGFloat = hoverPoints.first ?? 0
        
        let pts = getPrices(dropLastTwo: true)
        guard !pts.isEmpty else { return 0 }
        return chartLinearSeriesIndex(x: hoverPoint, width: chartSize.width, pointCount: pts.count)
    }
    
    // MARK: - Main coin functions
    
    func getMainCryptoInfo(id: String?) async {
        guard let cryptoDetails = await cryptoDetailRepository.getCurrencyDetails(id: id) else { return }
        cryptoInfo = cryptoDetails

    }

    func getCurrencyPrices(mainId: String?, compareId: String?, chart: TimeCharts) async {
        let (mainPriceModel, comparePriceModel) = await cryptoDetailRepository.getCompareCurrencyPrices(
            mainId: mainId,
            compareId: compareId,
            chart: chart
        )
        
        priceVolumeModel = mainPriceModel
        comparedPriceVolumeModel = comparePriceModel
        
        showMainPriceError = priceVolumeModel == nil
        showComparePriceError = comparedPriceVolumeModel == nil
    }
    
    func getPrices(dropLastTwo: Bool = false) -> [Double] {
        guard dropLastTwo, prices.count > 2 else {
            return prices
        }
        
        return Array(prices.dropLast(2))
    }
    
    func getTimestamps(dropLastTwo: Bool = false) -> [Double] {
        guard !showMainPriceError else { return [] }
        
        guard dropLastTwo, timeStamps.count > 2 else {
            return timeStamps
        }
        
        return Array(timeStamps.dropLast(2))
    }
    
    // MARK: - Compare coin functions
    
    func getCompareCryptoInfo(id: String?) async {
        guard let compareCryptoDetails = await cryptoDetailRepository.getCurrencyDetails(id: id) else { return }
        
        comparedCryptoInfo = compareCryptoDetails
    }
    
    func getCompareCurrencyPrices(id: String?, chart: TimeCharts) async {
        comparedPriceVolumeModel = await cryptoDetailRepository.getCurrencyPrices(
            id: id,
            chart: chart
        )
        
        showComparePriceError = comparedPriceVolumeModel == nil
    }
    
    func getComparePrices(dropLastTwo: Bool = false) -> [Double] {
        guard dropLastTwo, comparePrices.count > 2 else {
            return comparePrices
        }
        
        return Array(comparePrices.dropLast(2))
    }
    
    func getCompareTimestamps(dropLastTwo: Bool = false) -> [Double] {
        let timestamps = compareTimeStamps.map { $0.safeValue }
        
        guard dropLastTwo, timestamps.count > 2 else {
            return timestamps
        }
        
        return Array(timestamps.dropLast(2))
    }
    
    // Hover
    
    func updateHoverStats(touches: [CGPoint]) {
        guard !mainReloading, !compareReloading else { return }
        guard !timeStamps.isEmpty, !touches.isEmpty else {
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
        
        let adjustedTouches = [touches.first ?? .zero]
        
        hoverHelper.offset = adjustedTouches.map {
            CGPoint(x: max(0, min($0.x, chartSize.width.rounded(.down) - 0.00001)), y: $0.y)
        }
        
        hoverHelper.getHoverPrice(
            readerSize: chartSize,
            offset: hoverHelper.offset,
            prices: getPrices(dropLastTwo: true),
            dates: getTimestamps(dropLastTwo: true),
            timeChart: selectedTimeFrame,
            compareDates: getCompareTimestamps(dropLastTwo: true),
            comparePrices: getComparePrices(dropLastTwo: true),
            isDragging: isDragging
        )
        
        hoverHelper.getCompareHoverPrice(
            readerSize: chartSize,
            offset: hoverHelper.offset.first ?? .zero,
            prices: getComparePrices(dropLastTwo: true),
            dates: getCompareTimestamps(dropLastTwo: true),
            timeChart: selectedTimeFrame
        )
    }
    
    func point(
        at index: Int,
        rect: CGSize,
        prices: [Double],
    ) -> CGPoint {
        guard index >= 0 else { return .zero }
        
        let chartPrices = normalizedCompareChartPrices(from: prices)
        guard !chartPrices.isEmpty else { return .zero }
        
        let rawValue = chartPrices[safely: index] ?? 0
        let normalizedValue = rawValue == -1 ? 0.5 : rawValue
        let denom = max(chartPrices.count - 1, 1)
        let x = rect.width * Double(index) / Double(denom)
        let y = (1 - normalizedValue) * rect.height
        
        return CGPoint(x: x - 0.5, y: y.isNaN ? 0.5 * rect.height : y)
    }
    
    /// Matches `NewChartView.realPrices`: normalize using the full series (including padding),
    /// then drop the synthetic tail points used only for compare-chart scaling.
    private func normalizedCompareChartPrices(from prices: [Double], dropCount: Int = 2) -> [Double] {
        guard !prices.isEmpty, let firstPrice = prices.first else { return [] }
        
        var minValue = Double.infinity
        var maxValue = -Double.infinity
        var allSame = true
        
        for price in prices {
            if price != -1 {
                if price < minValue { minValue = price }
                if price > maxValue { maxValue = price }
                if price != firstPrice { allSame = false }
            }
        }
        
        if allSame, minValue != Double.infinity {
            return Array(repeating: 0.5, count: max(0, prices.count - dropCount))
        }
        
        guard minValue != Double.infinity, maxValue != -Double.infinity else { return [] }
        
        let range = maxValue - minValue
        if range == 0 {
            return Array(repeating: 0.5, count: max(0, prices.count - dropCount))
        }
        
        let normalized = prices.map { price in
            price == -1 ? -1 : (price - minValue) / range
        }
        
        guard dropCount > 0, normalized.count > dropCount else { return normalized }
        return Array(normalized.dropLast(dropCount))
    }
    
    func stopLivePriceUpdates() async {
        await stopWebSocket()
    }
    
    func syncLivePriceUpdates() async {
        await startWebSocket(mainId: cryptoInfo?.id, compareId: comparedCryptoInfo?.id)
    }
    
    private func startWebSocket(mainId: String?, compareId: String?) async {
        let coinIds = [mainId, compareId]
            .compactMap { $0?.lowercased() }
            .filter { !$0.isEmpty }
        
        guard isWebSocketEnabled, !coinIds.isEmpty else {
            await stopWebSocket()
            return
        }
        
        let connected = await cryptoDetailRepository.connectSignalR { [weak self] update in
            Task { @MainActor [weak self] in
                self?.applyWebSocketUpdate(update)
            }
        }
        
        guard connected else { return }
        
        _ = await cryptoDetailRepository.getCurrencies(coinIds: coinIds)
    }
    
    private func stopWebSocket() async {
        await cryptoDetailRepository.disconnectSignalR()
    }
    
    private func applyWebSocketUpdate(_ update: CGSimplePriceUpdate) {
        guard let updateCoinId = update.coinId?.lowercased() else { return }
        
        let selectedCurrency = (settingsManager.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code.lowercased()
        guard update.vsCurrency?.lowercased() == selectedCurrency else { return }
        
        if updateCoinId == cryptoInfo?.id?.lowercased() {
            let existing = cryptoInfo ?? CurrencyDataModel(id: updateCoinId)
            cryptoInfo = update.apply(to: existing)
            
            if currentChartType == .price, let livePrice = update.price {
                updateLastLivePrice(livePrice, onlyPrices: &onlyPrices, chartPrices: &prices)
            }
        } else if updateCoinId == comparedCryptoInfo?.id?.lowercased() {
            let existing = comparedCryptoInfo ?? CurrencyDataModel(id: updateCoinId)
            comparedCryptoInfo = update.apply(to: existing)
            
            if currentChartType == .price, let livePrice = update.price {
                updateLastLivePrice(livePrice, onlyPrices: &onlyComparePrices, chartPrices: &comparePrices)
            }
        }
    }
    
    private func updateLastLivePrice(
        _ livePrice: Double,
        onlyPrices: inout [Double],
        chartPrices: inout [Double]
    ) {
        guard !onlyPrices.isEmpty else { return }
        
        var updatedOnlyPrices = onlyPrices
        updatedOnlyPrices[updatedOnlyPrices.count - 1] = livePrice
        onlyPrices = updatedOnlyPrices
        
        guard !chartPrices.isEmpty else { return }
        
        var updatedChartPrices = chartPrices
        if updatedChartPrices.count > 2 {
            updatedChartPrices[updatedChartPrices.count - 3] = livePrice
        } else {
            updatedChartPrices[updatedChartPrices.count - 1] = livePrice
        }
        chartPrices = updatedChartPrices
    }
}
