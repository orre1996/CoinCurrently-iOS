//
//  TreasuryDetailViewModel.swift
//  CoinCurrently
//

import SwiftUI
import Combine

@MainActor
protocol TreasuryDetailViewModel {
    var treasuryDetail: TreasuryDetailEntity? { get set }
    var holdingChart: TreasuryHoldingChartModel? { get set }
    var transactionHistory: TreasuryTransactionHistoryModel? { get set }
    var availableHoldingCoins: [Toplist] { get }
    var selectedTransactionHoldingCoinId: String? { get set }
    var currentCurrency: CurrencyDataModel? { get set }
    var selectedTimeFrame: TimeCharts { get set }
    var selectedCurrency: CurrencyModel { get set }
    var showMainPriceError: Bool { get set }
    var prices: [Double] { get set }
    var onlyPrices: [Double] { get set }
    var timeStamps: [Double] { get set }
    var isDragging: Bool { get set }
    var hoverHelper: HoverHelper { get set }
    var hoverPriceWidthSize: CGFloat { get set }
    var hoverTimeWidthSize: CGFloat { get set }
    var chartSize: CGSize { get set }
    var mainReloading: Bool { get set }
    var currentDays: String { get set }
    var treasuryId: String { get }
    var coinId: String { get }
    var coinSymbol: String { get }
    var mainGraphStats: [String?] { get }
    var differenceValue: String { get }
    var differencePercent: String { get }
    var graphColor: Color { get }
    var changePercent: Double? { get }
    var hoverTime: String { get }
    var hoverPrice: String { get }
    var hoverTimePosition: CGFloat { get }
    var hoverPricePosition: CGFloat { get }
    var mainDragIndex: [Int] { get }
    var dragPositions: [CGPoint] { get }

    func setStartData() async
    func setSelectedCurrency() async
    func getCurrentCurrency() async
    func getDetail() async
    func getHoldingChart(days: String) async
    func getTransactionHistory() async
    func setTransactionHoldingFilter(_ coin: Toplist?) async
    func refresh(newDays: String?, newTimeChart: TimeCharts?) async
    func getPrices() -> [Double]
    func getOnlyPrices() -> [Double]
    func setPrices()
    func setOnlyPrices()
    func getPriceInChart(prices: [Double], at index: Int) -> String?
    func getTimestamps() -> [Double]
    func setTimestamps()
    func point(at index: Int, rect: CGSize) -> CGPoint
    func updateHoverStats(touches: [CGPoint])
}

@MainActor @Observable
final class TreasuryDetailViewModelImp: TreasuryDetailViewModel {
    private let treasuryDetailRepository: TreasuryDetailRepository
    private let cryptoDetailRepository: CryptoDetailRepository
    private let globalRepository: GlobalMarketRepository
    private let toplistRepository: ToplistRepository

    var treasuryDetail: TreasuryDetailEntity?
    var holdingChart: TreasuryHoldingChartModel?
    var transactionHistory: TreasuryTransactionHistoryModel?
    private(set) var availableHoldingCoins = [Toplist]()
    var selectedTransactionHoldingCoinId: String?
    var currentCurrency: CurrencyDataModel?

    let treasuryId: String
    private(set) var coinId: String

    var selectedTimeFrame = ChartButton.getTreasuryStartTimeFrame()

    var selectedCurrency = CurrencyModel(currency: "", code: "", symbol: "", locale: "", suffix: true)
    var showMainPriceError = false

    var prices = [Double]()
    var onlyPrices = [Double]()
    var timeStamps = [Double]()

    var isDragging = false
    var hoverHelper = HoverHelper()

    var hoverPriceWidthSize: CGFloat = 0
    var hoverTimeWidthSize: CGFloat = 0
    var chartSize: CGSize = .zero

    var mainReloading = false
    var currentDays = ChartButton.getTreasuryStartTimeFrame().days
    private(set) var coinSymbol = ""

    private var timer: Timer?

    init(
        treasuryId: String,
        treasuryDetail: TreasuryDetailEntity,
        coinId: String,
        treasuryDetailRepository: TreasuryDetailRepository = TreasuryDetailRepositoryImp.shared,
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared,
        globalRepository: GlobalMarketRepository = GlobalMarketRepositoryImp.shared,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared
    ) {
        self.treasuryId = treasuryId
        self.treasuryDetail = treasuryDetail.copy(withId: treasuryId)
        self.coinId = coinId
        self.treasuryDetailRepository = treasuryDetailRepository
        self.cryptoDetailRepository = cryptoDetailRepository
        self.globalRepository = globalRepository
        self.toplistRepository = toplistRepository
    }

    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await globalRepository.ensureCacheLoaded()
        await treasuryDetailRepository.ensureCacheLoaded()

        let id = treasuryId
        if !id.isEmpty {
            await treasuryDetailRepository.loadCachedDataForTreasury(
                id: id,
                coinId: coinId,
                days: currentDays
            )
        }
        
        if !coinId.isEmpty {
            await cryptoDetailRepository.loadCachedDataForCoin(id: coinId, chart: selectedTimeFrame)
        }

        let data = await treasuryDetailRepository.cachedTreasuryDetails[id]?.data.copy(withId: id)
        treasuryDetail = data ?? treasuryDetail

        if let chart = await treasuryDetailRepository.cachedHoldingCharts["\(id)-\(coinId)-\(currentDays)"]?.data {
            holdingChart = chart
        }

        let historyCacheKey = "\(id)-\(selectedTransactionHoldingCoinId ?? "all")"
        if let history = await treasuryDetailRepository.cachedTransactionHistory[historyCacheKey]?.data {
            transactionHistory = history
        }

        if let currency = await cryptoDetailRepository.cachedCryptoDetail[coinId]?.data {
            currentCurrency = currency
        }

        await updateCoinSymbol()
        await updateAvailableHoldingCoins()
        await setSelectedCurrency()
        setPrices()
        setOnlyPrices()
        setTimestamps()
        showMainPriceError = prices.isEmpty
    }

    func setSelectedCurrency() async {
        selectedCurrency = nativeChartCurrency()
    }

    private func nativeChartCurrency() -> CurrencyModel {
        let symbol = coinSymbol
        let spelledSymbol = symbol.map { String($0) }.joined(separator: " ")

        return CurrencyModel(
            currency: spelledSymbol.isEmpty ? symbol : spelledSymbol,
            code: symbol,
            symbol: symbol,
            locale: "",
            suffix: true
        )
    }

    func getCurrentCurrency() async {
        if let currency = await cryptoDetailRepository.getCurrencyDetails(id: coinId) {
            currentCurrency = currency
        }
        await updateCoinSymbol()
    }

    private func updateCoinSymbol() async {
        if currentCurrency?.id == coinId,
           let symbol = currentCurrency?.symbol?.uppercased(),
           !symbol.isEmpty {
            coinSymbol = symbol
            return
        }

        let coinList = await globalRepository.cachedCoinList?.data ?? []
        coinSymbol = coinList.first(where: { $0.id == coinId })?.symbol?.uppercased() ?? coinId.uppercased()
    }

    func getDetail() async {
        if let detail = await treasuryDetailRepository.getTreasuryDetail(id: treasuryId) {
            treasuryDetail = detail
            await updateAvailableHoldingCoins()
        }
    }

    func getHoldingChart(days: String) async {
        holdingChart = await treasuryDetailRepository.getHoldingChart(
            id: treasuryId,
            coinId: coinId,
            days: days
        )
    }

    func getTransactionHistory() async {
        transactionHistory = await treasuryDetailRepository.getTransactionHistory(
            id: treasuryId,
            coinId: selectedTransactionHoldingCoinId
        )
    }

    func setTransactionHoldingFilter(_ coin: Toplist?) async {
        let newFilterId = coin?.id
        guard newFilterId != selectedTransactionHoldingCoinId else { return }

        selectedTransactionHoldingCoinId = newFilterId

        let chartCoinId: String
        let chartCoinSymbol: String?

        if let newFilterId {
            chartCoinId = newFilterId
            chartCoinSymbol = coin?.symbol?.uppercased()
        } else {
            if treasuryDetail?.holdings?.isEmpty != false {
                await getDetail()
            }

            guard let topCoinId = highestValueHoldingCoinId() else {
                await getTransactionHistory()
                return
            }

            chartCoinId = topCoinId
            chartCoinSymbol = availableHoldingCoins
                .first(where: { $0.id == topCoinId })?
                .symbol?
                .uppercased()
        }

        await setChartCoin(coinId: chartCoinId, symbol: chartCoinSymbol)
    }

    private func highestValueHoldingCoinId() -> String? {
        treasuryDetail?.holdings?
            .compactMap { holding -> (String, Double)? in
                guard let coinId = holding.coin_id else { return nil }
                return (coinId, holding.current_value_usd ?? 0)
            }
            .max(by: { $0.1 < $1.1 })?
            .0
    }

    private func setChartCoin(coinId newCoinId: String, symbol: String?) async {
        coinId = newCoinId

        if let symbol, !symbol.isEmpty {
            coinSymbol = symbol
        }

        prices = []
        onlyPrices = []
        timeStamps = []
        holdingChart = nil
        await setSelectedCurrency()
        await refresh()
    }

    private func updateAvailableHoldingCoins() async {
        let holdingIds = (treasuryDetail?.holdings ?? []).compactMap(\.coin_id)
        guard !holdingIds.isEmpty else {
            availableHoldingCoins = []
            return
        }

        let toplist = await toplistRepository.getMarketToplist(sortOption: .mktCapDesc, priceChange: .sevenDays, platformId: nil) ?? []
        let coinList = await globalRepository.cachedCoinList?.data ?? []

        availableHoldingCoins = holdingIds.map { id in
            if let coin = toplist.first(where: { $0.id == id }) {
                return coin
            }

            let meta = coinList.first(where: { $0.id == id })
            return Toplist(
                id: id,
                symbol: meta?.symbol,
                name: meta?.name ?? id.capitalized,
                image: nil
            )
        }
    }

    func refresh(
        newDays: String? = nil,
        newTimeChart: TimeCharts? = nil
    ) async {
        mainReloading = true

        let days = newDays ?? currentDays
        let chart = newTimeChart ?? selectedTimeFrame

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.getDetail() }
            group.addTask { await self.getCurrentCurrency() }
            group.addTask { await self.getHoldingChart(days: days) }
            group.addTask { await self.getTransactionHistory() }
        }

        currentDays = days
        selectedTimeFrame = chart

        await setSelectedCurrency()
        setPrices()
        setOnlyPrices()
        setTimestamps()
        showMainPriceError = prices.isEmpty

        mainReloading = false
    }

    func getPrices() -> [Double] {
        prices
    }

    func getOnlyPrices() -> [Double] {
        onlyPrices
    }

    func setPrices() {
        if let dataPoints = chartDataPoints() {
            prices = dataPoints.compactMap { ($0.last ?? 0) ?? 0 }
        } else if let fallback = fallbackChartSeries() {
            prices = fallback.prices
        } else {
            prices = []
        }
    }

    func setOnlyPrices() {
        if let dataPoints = chartDataPoints() {
            onlyPrices = dataPoints.compactMap { ($0.last ?? 0) ?? 0 }
        } else if let fallback = fallbackChartSeries() {
            onlyPrices = fallback.prices
        } else {
            onlyPrices = []
        }
    }

    /// Needs ≥2 points so line/hover math (`count - 1`) stays valid.
    private func chartDataPoints() -> [[Double?]]? {
        let dataPoints = holdingChart?.holdings ?? holdingChart?.prices

        guard let dataPoints, dataPoints.count >= 2 else { return nil }
        return dataPoints
    }

    private func fallbackHoldingValue() -> Double? {
        let holding = treasuryDetail?.holdings?.first { $0.coin_id == coinId }
        return holding?.amount
    }

    private func resolvedDayCount() -> Int {
        if let days = Int(currentDays), days > 0 { return days }
        if let days = Int(selectedTimeFrame.days), days > 0 { return days }
        return 30
    }

    /// Flat series from current holdings when the API returns an empty/sparse chart.
    private func fallbackChartSeries() -> (prices: [Double], timestamps: [Double])? {
        guard let value = fallbackHoldingValue() else { return nil }

        let days = resolvedDayCount()
        let pointCount = max(2, min(days, 90))
        let now = Date().timeIntervalSince1970 * 1000
        let start = now - (Double(days) * 24 * 60 * 60 * 1000)
        let step = (now - start) / Double(pointCount - 1)

        let prices = Array(repeating: value, count: pointCount)
        let timestamps = (0..<pointCount).map { start + Double($0) * step }
        return (prices, timestamps)
    }

    var mainGraphStats: [String?] {
        (0..<6).map { getPriceInChart(prices: getPrices(), at: $0) }
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

    func getTimestamps() -> [Double] {
        timeStamps
    }

    func setTimestamps() {
        if let dataPoints = chartDataPoints() {
            timeStamps = dataPoints.compactMap { $0.first ?? 0 }
            return
        }

        timeStamps = fallbackChartSeries()?.timestamps ?? []
    }

    var differenceValue: String {
        let first = hoverHelper.hoverPrices[safely: 0] ?? 0
        let second = hoverHelper.hoverPrices[safely: 1] ?? 0
        let percent = Double.getDifferenceInPercent(between: second, and: first)?.safeValue ?? 0
        let sign = percent.roundTo(places: 2) < 0 ? "" : "+"
        let difference = (second - first).formatCurrency(threshold: FormattingThreshold.million, currency: selectedCurrency)
        return "\(sign)\(difference)"
    }

    var differencePercent: String {
        let first = hoverHelper.hoverPrices[safely: 0] ?? 0
        let second = hoverHelper.hoverPrices[safely: 1] ?? 0
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

    var changePercent: Double? {
        guard let first = getPrices().first,
              let last = getPrices().last else {
            return nil
        }

        return Double.getDifferenceInPercent(between: last, and: first)?.roundTo(places: 7)
    }

    var hoverTime: String {
        hoverHelper.hoverTimes.first ?? "0"
    }

    var hoverPrice: String {
        hoverHelper.hoverPrices.first?.formatCurrency(threshold: FormattingThreshold.million, currency: selectedCurrency) ?? "0"
    }

    var hoverTimePosition: CGFloat {
        getXPosition(textSize: hoverTimeWidthSize) - hoverTimeWidthSize / 2
    }

    var hoverPricePosition: CGFloat {
        getXPosition(textSize: hoverPriceWidthSize) - hoverTimeWidthSize / 2
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
        mainDragIndex.map {
            point(at: $0, rect: CGSize(width: chartSize.width, height: chartSize.height))
        }
    }

    func point(at index: Int, rect: CGSize) -> CGPoint {
        calculatePoint(
            at: index,
            rect: rect,
            timestamps: getTimestamps(),
            prices: getPrices()
        )
    }

    func updateHoverStats(touches: [CGPoint]) {
        guard !mainReloading else { return }
        guard !timeStamps.isEmpty, !touches.isEmpty else {
            isDragging = false
            timer?.invalidate()
            return
        }

        if !isDragging {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.isDragging = !touches.isEmpty

                    if self.isDragging {
#if IS_APP
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
                    }
                }
            }
        }

        hoverHelper.offset = touches.map {
            CGPoint(x: max(0, min($0.x, chartSize.width.rounded(.down) - 0.00001)), y: $0.y)
        }

        hoverHelper.getHoverPrice(
            readerSize: chartSize,
            offset: hoverHelper.offset,
            prices: getPrices(),
            dates: getTimestamps(),
            timeChart: selectedTimeFrame,
            isDragging: isDragging
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
        guard !normalizedPrices.isEmpty else {
            return CGPoint(x: 0, y: 0.5 * rect.height)
        }

        let clampedIndex = min(max(0, index), normalizedPrices.count - 1)
        let pointValue = normalizedPrices[clampedIndex]

        guard normalizedPrices.count > 1 else {
            return CGPoint(
                x: rect.width / 2,
                y: (1 - pointValue) * rect.height
            )
        }

        let denominator = Double(normalizedPrices.count - 1)
        let x = rect.width * Double(clampedIndex) / denominator
        let y = (1 - pointValue) * rect.height

        return CGPoint(
            x: adjustXByHalfPixel ? x - 0.5 : x,
            y: y.isNaN ? 0.5 * rect.height : y
        )
    }

    private func getXPosition(textSize: CGFloat) -> CGFloat {
        let xPoint = getPrices().point(at: currentHoverIndex, rect: chartSize).x
        return getPriceXPosition(position: xPoint, textSize: textSize, readerWidthSize: chartSize.width)
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

        let pricesCount = CGFloat(getPrices().count)
        return chartLinearSeriesIndex(x: hoverPoint, width: chartSize.width, pointCount: Int(pricesCount))
    }
}
