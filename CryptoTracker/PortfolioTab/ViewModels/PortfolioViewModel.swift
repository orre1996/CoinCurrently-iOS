//
//  PortfolioViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2020-12-12.
//

import SwiftUI
import Combine
import UIKit

private func needsPieColor(_ color: String?) -> Bool {
    guard let color else { return true }
    return color.uppercased() == "#FFFFFF"
}

@MainActor
protocol PortfolioViewModel {
    var reloading: Bool { get }
    var portfolio: [Pie]? { get }
    var allPrices: [Cryptocurrency] { get }
    var scrollToTopActive: Bool { get }
    var groupedTransactions: [Date: [any PortfolioEvent]] { get }
    var prices: [Double] { get }
    var timeStamps: [Double] { get }
    var totalValue: Double? { get }
    var changePercent: Double? { get }
    var changeValue: Double? { get }
    var graphStats: [String?] { get }
    var chartValues: [String] { get }
    var profitLossPercent: Double? { get }
    var profitLossValue: Double? { get }
    var typeFilters: [NewTransactionType] { get set }
    var dateFilter: DateOption { get set }
    var coinFilters: [Toplist] { get set }
    var hideData: Bool { get set }
    var hoverHelper: HoverHelper { get set }
    var hoverPriceWidthSize: CGFloat { get set }
    var hoverTimeWidthSize: CGFloat { get set }
    var hoverCandleTimeWidthSize: CGFloat { get set }
    var chartSize: CGSize { get set }
    var isDragging: Bool { get set }
    var coinFilterList: [Toplist] { get }
    var unrealizedProfitLoss: Double? { get }
    var differenceValue: String { get }
    var differencePercent: String { get }
    var graphColor: Color { get }
    var changePercentGraph: Double? { get }
    var hoverTime: String { get }
    var hoverPrice: String { get }
    var hoverTimePosition: CGFloat { get }
    var hoverPricePosition: CGFloat { get }
    var mainDragIndex: [Int] { get }
    var dragPositions: [CGPoint] { get }
    var portfolioPieSlices: [PortfolioPieSlice] { get }
    var benchmarkCoin: Toplist? { get }
    var benchmarkPrices: [Double] { get }
    var chartDropCount: Int { get }

    func setStartData() async
    func setTotalValue()
    func hasBoughtPro() async -> Bool
    func toggleHideData()
    func setTimestamps()
    func setPrices() async
    func getPrices(dropLastTwo: Bool) -> [Double]
    func getTimeStamps(dropLastTwo: Bool) -> [Double]
    func getBenchmarkPrices(dropLastTwo: Bool) -> [Double]
    func setGroupTransactions() async
    func deleteTransaction(_ transaction: (any PortfolioEvent)?) async
    func setChangePercent()
    func setChangeValue()
    func setGraphStats()
    func setChartValues()
    func point(at index: Int, rect: CGSize) -> CGPoint
    func updateHoverStats(touches: [CGPoint])
    func setProfitLossPercent()
    func setProfitLossValue()
    func exportPortfolioCSV(onComplete: @escaping (Bool) -> Void)
    func exportPortfolioJSON(onComplete: @escaping (Bool) -> Void)
    func exportPortfolioText(onComplete: @escaping (Bool) -> Void)
    func exportPortfolioKoinly(onComplete: @escaping (Bool) -> Void)
    func exportPortfolioCoinTracker(onComplete: @escaping (Bool) -> Void)
    func exportPortfolioTokenTax(onComplete: @escaping (Bool) -> Void)
    func exportPortfolioZenLedger(onComplete: @escaping (Bool) -> Void)
    func refreshPortfolioData() async
    func refreshImportWallets() async
    func getCoinColors() async
    func calculatePortfolioTotal() async
    func findTransaction(transaction: String) async -> ((any PortfolioEvent)?, Toplist?)
    func setBenchmarkCoin(id: String) async
    func clearBenchmark()
}

@MainActor @Observable
final class PortfolioViewModelImp: PortfolioViewModel, ObservableObject {
    private var cancellable: Set<AnyCancellable> = []
    
    private(set) var reloading = true
    private(set) var portfolio: [Pie]?
    private(set) var allPrices = [Cryptocurrency]()
    private(set) var scrollToTopActive = false
    private(set) var groupedTransactions: [Date: [any PortfolioEvent]] = [:]
    
    private(set) var prices = [Double]()
    private(set) var timeStamps = [Double]()
    private var rawPrices = [Double]()
    private var rawTimeStamps = [Double]()
    private(set) var benchmarkCoin: Toplist?
    private(set) var benchmarkPrices = [Double]()
    private(set) var benchmarkTimeStamps = [Double]()
    private var rawBenchmarkPrices = [Double]()
    
    private(set) var totalValue: Double?
    private(set) var changePercent: Double?
    private(set) var changeValue: Double?
    private(set) var graphStats: [String?] = [nil, nil, nil, nil, nil, nil]
    private(set) var chartValues: [String] = []
    private(set) var profitLossPercent: Double?
    private(set) var profitLossValue: Double?
    private(set) var portfolioPieSlices: [PortfolioPieSlice] = []
    
    // MARK: - Cached Lookups for O(1) Access
    private var pricesByIdCache: [String: [String: Double]] = [:]
    private var transactionAmountsCache: [String: Double] = [:]
    
    var typeFilters: [NewTransactionType] = []
    var dateFilter: DateOption = .all
    var coinFilters: [Toplist] = []
    
    var hideData: Bool
    
    // Hover
    var hoverHelper = HoverHelper()
    
    var hoverPriceWidthSize: CGFloat = 0
    var hoverTimeWidthSize: CGFloat = 0
    var hoverCandleTimeWidthSize: CGFloat = 0
    var chartSize: CGSize = .zero
    var isDragging = false
    
    private var timer: Timer?
    
    private let portfolioRepository: PortfolioRepository
    private let cryptoDetailRepository: CryptoDetailRepository
    private let toplistRepository: ToplistRepository
    private let storeKitManager: StoreKitManager
    private let settingsManager: SettingsManager
    
    init(
        portfolioRepository: PortfolioRepository = PortfolioRepositoryImp.shared,
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared,
        settingsManager: SettingsManager = SettingsManager.shared,
    ) {
        self.portfolioRepository = portfolioRepository
        self.cryptoDetailRepository = cryptoDetailRepository
        self.toplistRepository = toplistRepository
        self.storeKitManager = storeKitManager
        self.settingsManager = settingsManager
        
        self.hideData = settingsManager.get(key: AppSettingKey.hidePortfolioValues) ?? false
    }
    
    // MARK: - Cache Management
    
    /// Rebuilds the price lookup cache for O(1) access by coin ID
    private func rebuildPriceCache() {
        pricesByIdCache = Dictionary(
            uniqueKeysWithValues: allPrices.compactMap { crypto in
                return (crypto.id, crypto.prices)
            }
        )
    }
    
    /// Rebuilds the transaction amounts cache for O(1) access by coin ID
    private func rebuildTransactionAmountsCache() {
        guard let portfolio else {
            transactionAmountsCache = [:]
            return
        }
        
        transactionAmountsCache = Dictionary(
            uniqueKeysWithValues: portfolio.compactMap { pie in
                guard let id = pie.data?.id else { return nil }
                return (id, portfolio.getAllTransactions(of: id).getAmount())
            }
        )
    }
    
    // MARK: - Consolidated Portfolio Processing
    
    /// Single method for processing portfolio data - eliminates code duplication
    private func processPortfolio(
        dataPies: [Pie],
        otherCoins: [Toplist],
        coinColors: [String: String] = [:]
    ) async -> [Pie] {
        await Task.detached(priority: .userInitiated) {
            var resolvedDataPies = dataPies.map { pie -> Pie in
                var pie = pie
                guard let id = pie.data?.id, needsPieColor(pie.color) else {
                    return pie
                }
                if let cachedColor = coinColors[id], !needsPieColor(cachedColor) {
                    pie.color = cachedColor
                }
                return pie
            }

            let filteredOtherPies = otherCoins
                .filter { otherCoin in
                    !resolvedDataPies.contains { $0.data?.id == otherCoin.id }
                }
                .map { otherCoin in
                    Pie(
                        data: otherCoin,
                        color: coinColors[otherCoin.id ?? ""]
                    )
                }
            
            var combined = resolvedDataPies + filteredOtherPies
            
            // Pre-compute amounts once for sorting
            let amounts: [String: Double] = Dictionary(
                uniqueKeysWithValues: combined.compactMap { pie in
                    guard let id = pie.data?.id else { return nil }
                    return (id, combined.getAllTransactions(of: id).getAmount())
                }
            )
            
            combined.sort { lhs, rhs in
                let lhsValue = (amounts[lhs.data?.id ?? ""] ?? 0) * (lhs.data?.current_price ?? 0)
                let rhsValue = (amounts[rhs.data?.id ?? ""] ?? 0) * (rhs.data?.current_price ?? 0)
                return lhsValue > rhsValue
            }
            
            return combined
        }.value
    }
    
    // MARK: - Data Loading
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await portfolioRepository.ensureCacheLoaded()
        
        // Fetch data off main thread
        let cachedPrices = await portfolioRepository.cachedPortfolioPrices?.data
        let cachedPie = await portfolioRepository.cachedPortfolioPies
        
        // Update prices and rebuild cache
        if let cachedPrices {
            self.allPrices = cachedPrices
            rebuildPriceCache()
        }
        
        // Process portfolio using consolidated method
        if let cachedPie, !cachedPie.data.isEmpty {
            let processedPortfolio = await processPortfolio(
                dataPies: cachedPie.data,
                otherCoins: cachedPie.otherCoins,
                coinColors: cachedPie.coinColors
            )
            self.portfolio = processedPortfolio
            rebuildTransactionAmountsCache()
        }
        
        if portfolio != nil && !allPrices.isEmpty {
            await calculatePortfolioTotal()
        }
    }
    
    var coinFilterList: [Toplist] {
        let mainList =
            portfolio?
                .filter { !($0.transactions.isEmpty && $0.swaps.isEmpty && $0.imports.isEmpty) }
                .compactMap { $0.data }
            ?? []

        return mainList
    }
    
    func setTotalValue() {
        guard let portfolio else {
            totalValue = nil
            return
        }

        let currencyCode = (settingsManager.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code.lowercased()
        
        // Use cached lookups - O(1) per coin instead of O(n)
        totalValue = portfolio.reduce(0.0) { sum, pie in
            guard let id = pie.data?.id else { return sum }
            let lastPrice = pricesByIdCache[id]?[currencyCode] ?? 0
            let amount = transactionAmountsCache[id] ?? 0
            return sum + lastPrice * amount
        }
    }

    func setPortfolioPieSlices() {
        guard let portfolio, let totalValue, totalValue > 0 else {
            portfolioPieSlices = []
            return
        }

        let currencyCode = (settingsManager.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code.lowercased()
        let outerGap = PortfolioPieChartLayout.outerGapDegrees
        let innerGap = PortfolioPieChartLayout.innerGapDegrees

        let holdings: [(pie: Pie, value: Double)] = portfolio.compactMap { pie in
            guard pie.shouldShow, let id = pie.data?.id else { return nil }
            guard !portfolio.getAllTransactions(of: id).isEmpty else { return nil }

            let lastPrice = pricesByIdCache[id]?[currencyCode] ?? 0
            let amount = transactionAmountsCache[id] ?? 0
            let value = lastPrice * amount
            guard value > 0 else { return nil }

            return (pie, value)
        }.sorted { $0.value > $1.value }

        guard !holdings.isEmpty else {
            portfolioPieSlices = []
            return
        }

        let sliceInputs = portfolioPieSliceInputs(from: holdings, totalValue: totalValue)
        let sliceCount = sliceInputs.count
        let effectiveOuterGap = sliceCount > 1 ? outerGap : 0
        let effectiveInnerGap = sliceCount > 1 ? innerGap : 0

        let outerAvailable = 360.0 - effectiveOuterGap * Double(sliceCount)
        let innerAvailable = 360.0 - effectiveInnerGap * Double(sliceCount)
        var outerCurrent = -90.0 + effectiveOuterGap / 2
        var innerCurrent = -90.0 + effectiveInnerGap / 2

        let percentages = sliceInputs.map { $0.value / totalValue }
        let visualWeights = portfolioPieVisualWeights(from: percentages)

        portfolioPieSlices = zip(sliceInputs, visualWeights).map { slice, visualWeight in
            let percentage = slice.value / totalValue
            let outerStart = outerCurrent
            let outerEnd = outerStart + visualWeight * outerAvailable
            let innerStart = innerCurrent
            let innerEnd = innerStart + visualWeight * innerAvailable
            outerCurrent = outerEnd + effectiveOuterGap
            innerCurrent = innerEnd + effectiveInnerGap

            return PortfolioPieSlice(
                id: slice.id,
                symbol: slice.symbol,
                percentage: percentage,
                color: slice.color,
                outerStartAngle: outerStart,
                outerEndAngle: outerEnd,
                innerStartAngle: innerStart,
                innerEndAngle: innerEnd
            )
        }
    }

    private func portfolioPieSliceInputs(
        from holdings: [(pie: Pie, value: Double)],
        totalValue: Double
    ) -> [(id: String, symbol: String, value: Double, color: String?)] {
        func input(for holding: (pie: Pie, value: Double)) -> (id: String, symbol: String, value: Double, color: String?) {
            (
                id: holding.pie.data?.id ?? UUID().uuidString,
                symbol: holding.pie.data?.symbol?.uppercased() ?? "",
                value: holding.value,
                color: holding.pie.color
            )
        }

        // With two or fewer coins, always show each holding — never collapse into Other.
        guard holdings.count > 2 else {
            return holdings.map(input)
        }

        let mainHoldings = holdings.filter { $0.value / totalValue >= PortfolioPieChartLayout.minimumSlicePercentage }
        let otherHoldings = holdings.filter { $0.value / totalValue < PortfolioPieChartLayout.minimumSlicePercentage }

        var sliceInputs = mainHoldings.map(input)

        if !otherHoldings.isEmpty {
            let otherValue = otherHoldings.reduce(0) { $0 + $1.value }
            sliceInputs.append((
                id: PortfolioPieChartLayout.otherSliceId,
                symbol: "OTHER",
                value: otherValue,
                color: nil
            ))
        }

        return sliceInputs
    }

    /// Guarantees each slice is at least `minimumSlicePercentage` of the chart; leftover angle is shared by true weight.
    private func portfolioPieVisualWeights(from percentages: [Double]) -> [Double] {
        let minimum = PortfolioPieChartLayout.minimumSlicePercentage
        let count = percentages.count
        guard count > 0 else { return [] }

        let reserved = Double(count) * minimum
        guard reserved < 1 else {
            return Array(repeating: 1.0 / Double(count), count: count)
        }

        let remaining = 1 - reserved
        return percentages.map { minimum + $0 * remaining }
    }
    
    func hasBoughtPro() async -> Bool {
        return await storeKitManager.currentSubscription != nil
    }
    
    func toggleHideData() {
        hideData.toggle()
        settingsManager.set(data: hideData, key: AppSettingKey.hidePortfolioValues)
    }
    
    func setTimestamps() {
        // This is a lightweight computation, safe to run on main thread
        let now = Date()
        let hourInterval: TimeInterval = 60 * 60
        let elements = portfolio?.max(by: {
            ($0.data?.sparkline_in_7d?.price.count ?? 0 > $1.data?.sparkline_in_7d?.price.count ?? 0)
        })?.data?.sparkline_in_7d?.price.count ?? 169

        timeStamps = (0..<elements).map { i in
            let timestamp = now.addingTimeInterval(-Double(elements - 1 - i) * hourInterval)
            return timestamp.timeIntervalSince1970 * 1000
        }
        rawTimeStamps = timeStamps
    }
    
    func setPrices() async {
        if !rawTimeStamps.isEmpty {
            timeStamps = rawTimeStamps
        }
        
        // Capture data needed for computation
        let portfolio = self.portfolio
        let timeStamps = self.timeStamps
        let priceCache = self.pricesByIdCache  // O(1) lookup instead of O(n)
        let currencyCode = (settingsManager.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code.lowercased()
        
        // Perform heavy computation off main thread
        let computedPrices = await Task.detached(priority: .userInitiated) { [portfolio, timeStamps, priceCache, currencyCode] in
            guard let portfolio = portfolio, !portfolio.isEmpty else {
                return [Double](repeating: 0.0, count: timeStamps.count)
            }
            
            // Pre-allocate array with zeros for better performance
            var prices = [Double](repeating: 0.0, count: timeStamps.count)
            
            for pie in portfolio {
                guard
                    let sparkline = pie.data?.sparkline_in_7d?.price,
                    let coinId = pie.data?.id
                else { continue }
                
                // O(1) lookup instead of O(n)
                let lastPrice = priceCache[coinId]?[currencyCode] ?? 0
                let offset = timeStamps.count - sparkline.count
                
                // Get transactions once per coin (not per sparkline point)
                let transactions = portfolio.getAllTransactions(of: coinId)
                
                for (index, value) in sparkline.enumerated() {
                    let globalIndex = index + offset
                    guard globalIndex >= 0, globalIndex < timeStamps.count else { continue }
                    
                    let date = Date(timeIntervalSince1970: timeStamps[globalIndex] / 1000)
                    let priceValue = (index == sparkline.count - 1) ? lastPrice : value
                    let amount = transactions.getAmount(before: date)
                    
                    prices[globalIndex] += amount * priceValue
                }
            }
            
            return prices
        }.value
        
        // Update property on main thread
        self.prices = computedPrices
        self.rawPrices = computedPrices
    }
    
    var chartDropCount: Int {
        benchmarkCoin == nil ? 0 : 2
    }
    
    func getPrices(dropLastTwo: Bool = false) -> [Double] {
        guard dropLastTwo, prices.count > 2 else {
            return prices
        }
        
        return Array(prices.dropLast(2))
    }
    
    func getTimeStamps(dropLastTwo: Bool = false) -> [Double] {
        guard dropLastTwo, timeStamps.count > 2 else {
            return timeStamps
        }
        
        return Array(timeStamps.dropLast(2))
    }
    
    func getBenchmarkPrices(dropLastTwo: Bool = false) -> [Double] {
        guard dropLastTwo, benchmarkPrices.count > 2 else {
            return benchmarkPrices
        }
        
        return Array(benchmarkPrices.dropLast(2))
    }
    
    func setBenchmarkCoin(id: String) async {
        guard let coin = await toplistRepository.getCoin(id: id) else {
            return
        }
        
        benchmarkCoin = coin
        setTimestamps()
        await setPrices()
        addExtraElementsToTimeline()
        setChangePercent()
        setChangeValue()
        setGraphStats()
        setChartValues()
    }
    
    func clearBenchmark() {
        benchmarkCoin = nil
        benchmarkPrices = []
        benchmarkTimeStamps = []
        rawBenchmarkPrices = []
        prices = rawPrices
        timeStamps = rawTimeStamps
        setChangePercent()
        setChangeValue()
        setGraphStats()
        setChartValues()
    }
    
    private func setBenchmarkSeries() {
        guard
            let sparkline = benchmarkCoin?.sparkline_in_7d?.price,
            !sparkline.isEmpty,
            !rawPrices.isEmpty,
            let firstPortfolio = rawPrices.first(where: { $0 != -1 }),
            firstPortfolio != 0
        else {
            benchmarkPrices = []
            benchmarkTimeStamps = []
            return
        }
        
        var sparklinePrices = sparkline
        if let lastPrice = benchmarkCoin?.current_price, !sparklinePrices.isEmpty {
            sparklinePrices[sparklinePrices.count - 1] = lastPrice
        }
        
        guard
            let firstBenchmark = sparklinePrices.first,
            firstBenchmark != 0
        else {
            benchmarkPrices = []
            benchmarkTimeStamps = []
            return
        }
        
        let offset = rawTimeStamps.count - sparklinePrices.count
        var alignedPrices = [Double](repeating: -1, count: rawTimeStamps.count)
        
        for (index, value) in sparklinePrices.enumerated() {
            let globalIndex = index + offset
            guard globalIndex >= 0, globalIndex < alignedPrices.count else { continue }
            alignedPrices[globalIndex] = firstPortfolio * (value / firstBenchmark)
        }
        
        benchmarkPrices = alignedPrices
        benchmarkTimeStamps = rawTimeStamps
        rawBenchmarkPrices = alignedPrices
    }
    
    private func addExtraElementsToTimeline() {
        prices = rawPrices
        timeStamps = rawTimeStamps
        benchmarkPrices = rawBenchmarkPrices
        benchmarkTimeStamps = rawTimeStamps
        
        guard benchmarkCoin != nil else {
            benchmarkPrices = []
            benchmarkTimeStamps = []
            rawBenchmarkPrices = []
            return
        }
        
        setBenchmarkSeries()
        
        guard !prices.isEmpty, !benchmarkPrices.isEmpty else {
            return
        }
        
        let validMain = prices.filter { $0 != -1 }
        let validCompare = benchmarkPrices.filter { $0 != -1 }
        
        guard
            let firstMain = validMain.first,
            let mainMax = validMain.max(),
            let mainMin = validMain.min(),
            let firstCompare = validCompare.first,
            let compareMax = validCompare.max(),
            let compareMin = validCompare.min(),
            firstCompare != 0
        else {
            return
        }
        
        let firstTimestamp = timeStamps.first(where: { $0 != -1 }) ?? timeStamps.first ?? 0
        let compareTimestamps = benchmarkTimeStamps.first(where: { $0 != -1 }) ?? benchmarkTimeStamps.first ?? 0
        
        let compareMaxPercent = Double.getDifferenceInDecimal(between: compareMax, and: firstCompare) ?? 0
        let compareMinPercent = Double.getDifferenceInDecimal(between: compareMin, and: firstCompare) ?? 0
        
        prices.append(contentsOf: [firstMain * compareMaxPercent, firstMain * compareMinPercent])
        
        let mainDate = Date(timeIntervalSince1970: TimeInterval((timeStamps.first(where: { $0 != -1 }) ?? 0) / 1000))
        let compareDate = Date(timeIntervalSince1970: TimeInterval((benchmarkTimeStamps.first(where: { $0 != -1 }) ?? 0) / 1000))
        
        if abs(mainDate.timeIntervalSince(compareDate)) > Date.moreThanADay {
            timeStamps.append(contentsOf: [compareTimestamps, compareTimestamps])
        } else {
            timeStamps.append(contentsOf: [firstTimestamp, firstTimestamp])
        }
        
        let mainMaxPercent = Double.getDifferenceInDecimal(between: mainMax, and: firstMain) ?? 0
        let mainMinPercent = Double.getDifferenceInDecimal(between: mainMin, and: firstMain) ?? 0
        
        benchmarkPrices.append(contentsOf: [firstCompare * mainMaxPercent, firstCompare * mainMinPercent])
        
        if abs(compareDate.timeIntervalSince(mainDate)) > Date.moreThanADay {
            benchmarkTimeStamps.append(contentsOf: [firstTimestamp, firstTimestamp])
        } else {
            benchmarkTimeStamps.append(contentsOf: [compareTimestamps, compareTimestamps])
        }
        
        let delta = abs(prices.count - benchmarkPrices.count)
        if prices.count > benchmarkPrices.count {
            benchmarkPrices.insert(contentsOf: Array(repeating: -1, count: delta), at: 0)
            benchmarkTimeStamps.insert(contentsOf: Array(repeating: -1, count: delta), at: 0)
        } else if benchmarkPrices.count > prices.count {
            prices.insert(contentsOf: Array(repeating: -1, count: delta), at: 0)
            timeStamps.insert(contentsOf: Array(repeating: -1, count: delta), at: 0)
        }
    }
    
    private var portfolioHoverPrices: [Double] {
        getPrices(dropLastTwo: benchmarkCoin != nil).enumerated().map { index, chartPrice in
            guard chartPrice != -1 else { return -1.0 }
            return portfolioRawValue(atChartIndex: index) ?? chartPrice
        }
    }
    
    private func portfolioRawValue(atChartIndex index: Int) -> Double? {
        guard index >= 0 else { return nil }
        
        let leadingPadding = prices.prefix(while: { $0 == -1 }).count
        let rawIndex = index - leadingPadding
        
        guard rawIndex >= 0, rawIndex < rawPrices.count else { return nil }
        return rawPrices[rawIndex]
    }
    
    func setGroupTransactions() async {
        // Capture data needed for computation
        let portfolio = self.portfolio
        let typeFilters = self.typeFilters
        let dateFilter = self.dateFilter
        let coinFilters = self.coinFilters
        
        // Perform computation off main thread
        let computedGroupedTransactions = await Task.detached(priority: .userInitiated) { [portfolio, typeFilters, dateFilter, coinFilters] in
            return portfolio?.groupedTransactions(
                types: typeFilters,
                on: dateFilter,
                coinNames: coinFilters
            ) ?? [:]
        }.value
        
        // Update property on main thread
        self.groupedTransactions = computedGroupedTransactions
    }
    
    func deleteTransaction(_ transaction: (any PortfolioEvent)?) async {
        guard let transaction else {
            return
        }
        
        // Get ID (we're already on MainActor since class is @MainActor)
        let id = portfolio?.pie(containing: transaction)?.data?.id ?? ""

        // Delete transaction off main thread
        let deletedPortfolio = await portfolioRepository.deleteTransaction(
            id: id,
            uuid: transaction.id
        )

        // Process portfolio using consolidated method
        let processedPortfolio = await processPortfolio(
            dataPies: deletedPortfolio?.data ?? [],
            otherCoins: deletedPortfolio?.otherCoins ?? [],
            coinColors: deletedPortfolio?.coinColors ?? [:]
        )

        // Update properties on main thread
        self.portfolio = processedPortfolio
        rebuildTransactionAmountsCache()
        await calculatePortfolioTotal()
    }

    var unrealizedProfitLoss: Double? {
        var spent: Double = 0
        let currentValue: Double = 0
        portfolio?.forEach { coin in
            coin.transactions.forEach { transaction in
                spent += transaction.amount * (transaction.pricePerCoin ?? 1)
            }
        }
        
        return currentValue / spent
    }
        
    func setChangePercent() {
        let chartPrices = rawPrices.filter { $0 != -1 }
        guard portfolio != nil, let firstPrice = chartPrices.first, let lastPrice = chartPrices.last else {
            changePercent = nil
            return
        }
        
        changePercent = Double.getDifferenceInPercent(between: lastPrice, and: firstPrice)
    }
    
    func setChangeValue() {
        let chartPrices = rawPrices.filter { $0 != -1 }
        guard portfolio != nil, let firstPrice = chartPrices.first, let lastPrice = chartPrices.last else {
            changeValue = nil
            return
        }
        
        changeValue = lastPrice - firstPrice
    }
    
    func setGraphStats() {
        guard let portfolio else {
            graphStats = (0..<6).map { _ in
                nil
            }

            return
        }
        
        guard !portfolio.isEmpty else {
            graphStats = (0..<6).map {
                Double($0 * 1).formatCurrency()
            }

            return
        }
        
        let validPrices: [Double] = {
            if benchmarkCoin != nil {
                return rawPrices.filter { $0 != -1 } + rawBenchmarkPrices.filter { $0 != -1 }
            }
            return rawPrices.filter { $0 != -1 }
        }()
        
        if validPrices.allSatisfy({ $0 == 0.0 }) {
            graphStats = (0..<6).map {
                Double($0 * 1).formatCurrency()
            }

            return
        }
        
        guard !hideData else {
            graphStats = (0..<6).map { _ in
                String.stars
            }

            return
        }

        graphStats = (0..<6).map {
            guard
                let minPrice = validPrices.min(),
                let maxPrice = validPrices.max()
            else {
                return nil
            }
            
            let step = (maxPrice - minPrice) / 5
            let value = minPrice + (step * Double($0))
            
            return value.formatCurrency()
        }
    }

    func setChartValues() {
        let steps: Double = 1 / 6
        let chartPrices = getPrices(dropLastTwo: benchmarkCoin != nil)
        
        guard !chartPrices.isEmpty else {
            chartValues = []
            return
        }

        chartValues = (1..<5).map { step in
            let i = Int(Double(chartPrices.count) * steps * Double(step))
            let price = portfolioRawValue(atChartIndex: i)?.formatCurrency(accessible: true)
                ?? chartPrices[safely: i]?.formatCurrency(accessible: true)
                ?? ""
            
            return "The price was \(price) on"
        }
    }

    var differenceValue: String {
        guard !hideData else {
            return String.stars
        }
        
        let first = hoverHelper.hoverPrices[safely: 0] ?? 0
        let second = hoverHelper.hoverPrices[safely: 1] ?? 0
        let percent = Double.getDifferenceInPercent(between: second, and: first)?.safeValue ?? 0
        let sign = percent.roundTo(places: 2) < 0 ? "" : "+"
        let difference = (second - first).formatCurrency(threshold: FormattingThreshold.billion)
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
    
    var changePercentGraph: Double? {
        let chartPrices = rawPrices.filter { $0 != -1 }
        guard let first = chartPrices.first,
              let last = chartPrices.last else {
            return nil
        }
        
        return Double.getDifferenceInPercent(between: last, and: first)?.roundTo(places: 7)
    }
    
    var hoverTime: String {
        return hoverHelper.hoverTimes.first ?? "0"
    }
    
    var hoverPrice: String {
        return hideData ? String.stars : hoverHelper.hoverPrices.first?.formatCurrency(threshold: FormattingThreshold.billion) ?? "0"
    }
    
    var hoverTimePosition: CGFloat {
        return getXPosition(textSize: hoverTimeWidthSize) - hoverTimeWidthSize / 2
    }
    
    var hoverPricePosition: CGFloat {
        return getXPosition(textSize: hoverPriceWidthSize) - hoverTimeWidthSize / 2
    }
    
    var mainDragIndex: [Int] {
        let chartPrices = getPrices(dropLastTwo: benchmarkCoin != nil)
        let chartTimeStamps = getTimeStamps(dropLastTwo: benchmarkCoin != nil)
        let pricesCount = CGFloat(chartPrices.count)
        let firstTimestamp = chartTimeStamps.normalized.first ?? 0
        let timestampCount = Double(chartTimeStamps.count)
        
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
    
    private func getXPosition(textSize: CGFloat) -> CGFloat {
        let xPoint = point(at: currentHoverIndex, rect: chartSize).x
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
        
        let pricesCount = CGFloat(getPrices(dropLastTwo: benchmarkCoin != nil).count)
        return chartLinearSeriesIndex(x: hoverPoint, width: chartSize.width, pointCount: Int(pricesCount))
    }
    
    var dragPositions: [CGPoint] {
        return mainDragIndex.map({
            point(at: $0, rect: CGSize(width: chartSize.width, height: chartSize.height))
        })
    }
    
    func point(at index: Int, rect: CGSize) -> CGPoint {
        let normalized = normalizedChartPrices(prices, dropCount: chartDropCount)
        let pointValue = normalized[safely: index] ?? 0
        let denominator = max(1, normalized.count - 1)
        let x = rect.width * Double(index) / Double(denominator)
        let y = (1 - pointValue) * rect.height
        
        let chartValues = getPrices(dropLastTwo: benchmarkCoin != nil)
        let isEmpty = portfolio?.isEmpty ?? true || chartValues.allSatisfy { $0 == 0 || $0 == -1 }
        
        return CGPoint(
            x: x - 0.5,
            y: isEmpty ? rect.height : (y.isNaN ? 0.5 * rect.height : y)
        )
    }
    
    private func normalizedChartPrices(_ prices: [Double], dropCount: Int = 0) -> [Double] {
        guard !prices.isEmpty else { return [] }
        
        var minValue = Double.infinity
        var maxValue = -Double.infinity
        
        for price in prices where price != -1 {
            if price < minValue { minValue = price }
            if price > maxValue { maxValue = price }
        }
        
        guard minValue != Double.infinity, maxValue != minValue else {
            return Array(repeating: 0.5, count: max(0, prices.count - dropCount))
        }
        
        let normalized = prices.map { price in
            price == -1 ? -1 : (price - minValue) / (maxValue - minValue)
        }
        
        guard dropCount > 0 else { return normalized }
        return Array(normalized.dropLast(dropCount))
    }
    
    func updateHoverStats(touches: [CGPoint]) {
        guard portfolio != nil else {
            return
        }
        
        guard (!getTimeStamps(dropLastTwo: benchmarkCoin != nil).isEmpty) && !touches.isEmpty else {
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
        
        hoverHelper.offset = touches.map {
            CGPoint(x: max(0, min($0.x, chartSize.width.rounded(.down) - 0.00001)), y: $0.y)
        }
        
        hoverHelper.getHoverPrice(
            readerSize: chartSize,
            offset: hoverHelper.offset,
            prices: benchmarkCoin == nil ? rawPrices : portfolioHoverPrices,
            dates: getTimeStamps(dropLastTwo: benchmarkCoin != nil),
            timeChart: .aWeek,
            isDragging: isDragging
        )
    }
    
    func setProfitLossPercent() {
        guard let portfolio else {
            profitLossPercent = nil
            return
        }
        
        let selectedCurrency: CurrencyModel = settingsManager.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        profitLossPercent = GlobalFunctions.shared.getPortfolioProfitLossPercent(
            of: portfolio,
            coinPrices: allPrices,
            showCurrency: selectedCurrency.code
        )
    }
    
    func setProfitLossValue() {
        guard let portfolio else {
            profitLossValue = nil
            return
        }

        let selectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        
        profitLossValue = GlobalFunctions.shared.getPortfolioProfitLossValue(
            of: portfolio,
            coinPrices: allPrices,
            showCurrency: selectedCurrency.code
        )
    }
    
    func exportPortfolioCSV(onComplete: @escaping (Bool) -> Void = { _ in }) {
        guard let portfolio else {
            onComplete(false)
            return
        }
        
        var rows = ["Date (UTC),Coin,Type,Amount,Price per coin,Fee,Value traded,Currency,Note,Address"]
        var entries: [(date: Date, row: String)] = []
        
        for pie in portfolio {
            let coin = pie.data?.symbol?.uppercased() ?? pie.data?.name ?? ""
            
            for transaction in pie.transactions {
                entries.append((transaction.date, csvRow(coin: coin, transaction: transaction)))
            }
            
            for swap in pie.swaps {
                entries.append((swap.date, csvSwapRow(swap: swap)))
            }
            
            for importEvent in pie.imports {
                entries.append((importEvent.date, csvImportRow(coin: coin, importEvent: importEvent)))
            }
        }
        
        rows += entries
            .sorted { $0.date > $1.date }
            .map(\.row)
        
        shareExport(content: rows.joined(separator: "\n"), extensionName: "csv", onComplete: onComplete)
    }
    
    func exportPortfolioJSON(onComplete: @escaping (Bool) -> Void = { _ in }) {
        guard let portfolio else {
            onComplete(false)
            return
        }
        
        let models = portfolio.compactMap(\.toPortfolioExportModel)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        guard
            let jsonData = try? encoder.encode(models),
            let jsonString = String(data: jsonData, encoding: .utf8)
        else {
            onComplete(false)
            return
        }
        
        shareExport(content: jsonString, extensionName: "json", onComplete: onComplete)
    }
    
    func exportPortfolioText(onComplete: @escaping (Bool) -> Void = { _ in }) {
        guard let portfolio else {
            onComplete(false)
            return
        }
        
        let text = portfolio
            .map(textExportSection(for:))
            .joined()
            .trimmingCharacters(in: .newlines)
        
        guard !text.isEmpty else {
            onComplete(false)
            return
        }
        
        shareExport(content: text, extensionName: "txt", onComplete: onComplete)
    }
    
    func exportPortfolioKoinly(onComplete: @escaping (Bool) -> Void = { _ in }) {
        guard let portfolio else {
            onComplete(false)
            return
        }
        
        exportTaxCSV(
            content: PortfolioTaxExportBuilder.koinlyCSV(from: portfolio),
            fileName: "CoinCurrently-Portfolio-Koinly",
            onComplete: onComplete
        )
    }
    
    func exportPortfolioCoinTracker(onComplete: @escaping (Bool) -> Void = { _ in }) {
        guard let portfolio else {
            onComplete(false)
            return
        }
        
        exportTaxCSV(
            content: PortfolioTaxExportBuilder.coinTrackerCSV(from: portfolio),
            fileName: "CoinCurrently-Portfolio-CoinTracker",
            onComplete: onComplete
        )
    }
    
    func exportPortfolioTokenTax(onComplete: @escaping (Bool) -> Void = { _ in }) {
        guard let portfolio else {
            onComplete(false)
            return
        }
        
        exportTaxCSV(
            content: PortfolioTaxExportBuilder.tokenTaxCSV(from: portfolio),
            fileName: "CoinCurrently-Portfolio-TokenTax",
            onComplete: onComplete
        )
    }
    
    func exportPortfolioZenLedger(onComplete: @escaping (Bool) -> Void = { _ in }) {
        guard let portfolio else {
            onComplete(false)
            return
        }
        
        exportTaxCSV(
            content: PortfolioTaxExportBuilder.zenLedgerCSV(from: portfolio),
            fileName: "CoinCurrently-Portfolio-ZenLedger",
            onComplete: onComplete
        )
    }
    
    private func exportTaxCSV(content: String, fileName: String, onComplete: @escaping (Bool) -> Void) {
        shareExport(content: content, extensionName: "csv", fileName: fileName, onComplete: onComplete)
    }
    
    private func shareExport(content: String, extensionName: String, onComplete: @escaping (Bool) -> Void) {
        shareExport(content: content, extensionName: extensionName, fileName: "CoinCurrently-Portfolio", onComplete: onComplete)
    }
    
    private func shareExport(
        content: String,
        extensionName: String,
        fileName: String,
        onComplete: @escaping (Bool) -> Void
    ) {
        let fileURL = content.createFile(fileName, extensionName: extensionName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            onComplete(false)
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        activityViewController.completionWithItemsHandler = { _, completed, _, _ in
            try? FileManager.default.removeItem(at: fileURL)
            onComplete(completed)
        }
        
        if let popover = activityViewController.popoverPresentationController,
           let rootView = UIApplication.shared.window?.rootViewController?.view {
            popover.sourceView = rootView
            popover.sourceRect = .zero
            popover.permittedArrowDirections = []
        }
        
        UIApplication.shared.window?.rootViewController?.present(activityViewController, animated: true)
    }
    
    private func csvField(_ value: String) -> String {
        value.replacingOccurrences(of: ",", with: ".")
    }
    
    private func csvNumericField(_ value: Double?) -> String {
        guard let value else { return "" }
        return csvField(value.description)
    }
    
    private func csvRow(coin: String, transaction: NewTransaction) -> String {
        let isTransfer = transaction.transactionType.isTransfer
        let value = (transaction.amount * (transaction.pricePerCoin ?? 0)) + transaction.fee
        
        return [
            transaction.date.portfolioExportDateTimeUTC,
            coin,
            transaction.transactionType.rawValue,
            csvField("\(transaction.amount)"),
            isTransfer ? "" : csvNumericField(transaction.pricePerCoin),
            isTransfer ? "" : csvNumericField(transaction.fee),
            isTransfer || value == 0 ? "" : csvNumericField(value),
            isTransfer ? "" : csvField(transaction.currency),
            csvField(transaction.note),
            csvField(transaction.address ?? "")
        ].joined(separator: ",")
    }
    
    private func csvSwapRow(swap: NewSwapTransaction) -> String {
        let coin = "\(swap.fromCurrencySymbol.uppercased()) → \(swap.toCurrencySymbol.uppercased())"
        let value = (swap.fromAmount * swap.fromUnitPrice) + swap.fee
        
        return [
            swap.date.portfolioExportDateTimeUTC,
            coin,
            NewTransactionType.swap.rawValue,
            csvField("\(swap.fromAmount)"),
            csvNumericField(swap.fromUnitPrice),
            csvNumericField(swap.fee),
            value == 0 ? "" : csvNumericField(value),
            csvField(swap.selectedCurrency),
            csvField(swap.note),
            ""
        ].joined(separator: ",")
    }
    
    private func csvImportRow(coin: String, importEvent: AddressImport) -> String {
        [
            importEvent.date.portfolioExportDateTimeUTC,
            coin,
            NewTransactionType.importAddress.rawValue,
            csvField(importEvent.balance),
            "",
            "",
            "",
            "",
            csvField(importEvent.walletName ?? ""),
            csvField(importEvent.address)
        ].joined(separator: ",")
    }
    
    private func textExportSection(for pie: Pie) -> String {
        let coinName = pie.data?.name ?? pie.data?.symbol?.uppercased() ?? "Coin"
        var section = "• \(coinName)\n\n"
        
        let transactionsByType = Dictionary(grouping: pie.transactions, by: \.transactionType)
        
        for type in [NewTransactionType.buy, .sell, .transferIn, .transferOut] {
            guard let transactions = transactionsByType[type], !transactions.isEmpty else { continue }
            section += "-- \(type.rawValue) Transactions --\n"
            section += transactions
                .sorted { $0.date > $1.date }
                .map { textExportBlock(for: $0) }
                .joined()
        }
        
        if !pie.swaps.isEmpty {
            section += "-- Swap Transactions --\n"
            section += pie.swaps
                .sorted { $0.date > $1.date }
                .map(textExportBlock(for:))
                .joined()
        }
        
        if !pie.imports.isEmpty {
            section += "-- Wallet Imports --\n"
            section += pie.imports
                .sorted { $0.date > $1.date }
                .map(textExportBlock(for:))
                .joined()
        }
        
        return section
    }
    
    private func textExportBlock(for transaction: NewTransaction) -> String {
        let selectedCurrency = CurrencyModel.allCurrencies.first {
            $0.code.lowercased() == transaction.currency.lowercased()
        }
        var block = "Date (UTC): \(transaction.date.portfolioExportDateTimeUTC)\n"
        block += "Amount: \(transaction.amount)\n"
        
        if !transaction.transactionType.isTransfer, let pricePerCoin = transaction.pricePerCoin {
            block += "Price per coin: \(pricePerCoin.getFormattedString(dontShort: true, selectedCurrency: selectedCurrency))\n"
        }
        
        if !transaction.transactionType.isTransfer, transaction.fee != 0 {
            block += "Fee: \(transaction.fee.getFormattedString(dontShort: true, selectedCurrency: selectedCurrency))\n"
        }
        
        let value = (transaction.amount * (transaction.pricePerCoin ?? 0)) + transaction.fee
        if !transaction.transactionType.isTransfer, value != 0 {
            block += "Value traded: \(value.getFormattedString(dontShort: true, selectedCurrency: selectedCurrency))\n"
        }
        
        if !transaction.transactionType.isTransfer {
            block += "Currency: \(transaction.currency)\n"
        }
        
        if !transaction.note.isEmpty {
            block += "Note: \(transaction.note)\n"
        }
        
        if let address = transaction.address, !address.isEmpty {
            block += "Address: \(address)\n"
        }
        
        return block + "\n"
    }
    
    private func textExportBlock(for swap: NewSwapTransaction) -> String {
        let selectedCurrency = CurrencyModel.allCurrencies.first {
            $0.code.lowercased() == swap.selectedCurrency.lowercased()
        }
        var block = "Date (UTC): \(swap.date.portfolioExportDateTimeUTC)\n"
        block += "From: \(swap.fromAmount) \(swap.fromCurrencySymbol.uppercased()) @ \(swap.fromUnitPrice.getFormattedString(dontShort: true, selectedCurrency: selectedCurrency))\n"
        block += "To: \(swap.toAmount) \(swap.toCurrencySymbol.uppercased()) @ \(swap.toUnitPrice.getFormattedString(dontShort: true, selectedCurrency: selectedCurrency))\n"
        
        if swap.fee != 0 {
            block += "Fee: \(swap.fee.getFormattedString(dontShort: true, selectedCurrency: selectedCurrency))\n"
        }
        
        if !swap.note.isEmpty {
            block += "Note: \(swap.note)\n"
        }
        
        return block + "\n"
    }
    
    private func textExportBlock(for importEvent: AddressImport) -> String {
        var block = "Date (UTC): \(importEvent.date.portfolioExportDateTimeUTC)\n"
        
        if let walletName = importEvent.walletName, !walletName.isEmpty {
            block += "Wallet: \(walletName)\n"
        }
        
        block += "Address: \(importEvent.address)\n"
        block += "Balance: \(importEvent.balance)\n"
        return block + "\n"
    }

    func refreshPortfolioData() async {
        // Start both network calls in parallel - they download simultaneously
        async let portfolioTask = portfolioRepository.getPortfolio()
        async let currenciesTask = portfolioRepository.getPortfolioAllCurrencies()
        
        // Wait for both network calls to complete
        let fetchedPortfolio = await portfolioTask
        let allCurrencies = await currenciesTask
        let cachedPortfolio = await portfolioRepository.cachedPortfolioPies
        
        // Update prices and rebuild cache first
        if let allCurrencies {
            self.allPrices = allCurrencies
            rebuildPriceCache()
        }
        
        // Process portfolio using consolidated method
        let processedPortfolio = await processPortfolio(
            dataPies: fetchedPortfolio?.data ?? cachedPortfolio?.data ?? self.portfolio ?? [],
            otherCoins: fetchedPortfolio?.otherCoins ?? cachedPortfolio?.otherCoins ?? [],
            coinColors: fetchedPortfolio?.coinColors ?? cachedPortfolio?.coinColors ?? [:]
        )

        // Update properties on main thread
        self.portfolio = processedPortfolio
        rebuildTransactionAmountsCache()
        
        if let benchmarkId = benchmarkCoin?.id,
           let coin = await toplistRepository.getCoin(id: benchmarkId) {
            benchmarkCoin = coin
        }
        
        // Calculate portfolio total only once after both updates
        await calculatePortfolioTotal()
    }
    
    func refreshImportWallets() async {
        // Refresh wallets off main thread
        let refreshedPortfolio = await portfolioRepository.refreshWallets()
        
        guard let refreshedPortfolio else { return }
        
        // Process portfolio using consolidated method
        let processedPortfolio = await processPortfolio(
            dataPies: refreshedPortfolio.data,
            otherCoins: refreshedPortfolio.otherCoins,
            coinColors: refreshedPortfolio.coinColors
        )

        // Update properties on main thread
        self.portfolio = processedPortfolio
        rebuildTransactionAmountsCache()
        await calculatePortfolioTotal()
    }

    func getCoinColors() async {
        for await _ in await portfolioRepository.getCoinColors() {
            await reloadPortfolioFromCache()
            setPortfolioPieSlices()
        }
    }

    private func reloadPortfolioFromCache() async {
        guard let cachedPortfolio = await portfolioRepository.cachedPortfolioPies else { return }

        portfolio = await processPortfolio(
            dataPies: cachedPortfolio.data,
            otherCoins: cachedPortfolio.otherCoins,
            coinColors: cachedPortfolio.coinColors
        )
    }

    func calculatePortfolioTotal() async {
        // setTimestamps() is lightweight and can run on main thread
        setTimestamps()
        
        // Run setPrices() and setGroupTransactions() in parallel since they don't depend on each other
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.setPrices() }
            group.addTask { await self.setGroupTransactions() }
        }
        
        addExtraElementsToTimeline()
        
        // Set computed values after all data is ready (batch synchronous updates)
        setTotalValue()
        setChangePercent()
        setChangeValue()
        setGraphStats()
        setChartValues()
        setProfitLossPercent()
        setProfitLossValue()
        setPortfolioPieSlices()

        self.reloading = false
    }
    
    func findTransaction(transaction: String) async -> ((any PortfolioEvent)?, Toplist?) {
        await portfolioRepository.findTransaction(lookup: transaction)
    }
}
