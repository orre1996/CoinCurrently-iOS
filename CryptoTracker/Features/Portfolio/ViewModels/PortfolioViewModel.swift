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
protocol PortfolioViewModel: ChartHoverHosting {
    var reloading: Bool { get }
    var portfolio: [Pie]? { get }
    var allPrices: [Cryptocurrency] { get }
    var scrollToTopActive: Bool { get }
    var prices: [Double] { get }
    var timeStamps: [Double] { get }
    var changePercent: Double? { get }
    var changeValue: Double? { get }
    var graphStats: [String?] { get }
    var chartValues: [String] { get }
    var hideData: Bool { get set }
    var unrealizedProfitLoss: Double? { get }
    var graphColor: Color { get }
    var changePercentGraph: Double? { get }
    var hoverTimePosition: CGFloat { get }
    var hoverPricePosition: CGFloat { get }
    var mainDragIndex: [Int] { get }
    var dragPositions: [CGPoint] { get }
    var benchmarkCoin: Toplist? { get }
    var benchmarkPrices: [Double] { get }
    var chartDropCount: Int { get }

    func setStartData() async
    func hasBoughtPro() async -> Bool
    func toggleHideData()
    func setTimestamps()
    func setPrices() async
    func getPrices(dropLastTwo: Bool) -> [Double]
    func getTimeStamps(dropLastTwo: Bool) -> [Double]
    func getBenchmarkPrices(dropLastTwo: Bool) -> [Double]
    func reloadTransactions() async
    func deleteTransaction(_ transaction: (any PortfolioEvent)?) async
    func setChangePercent()
    func setChangeValue()
    func setGraphStats()
    func setChartValues()
    func point(at index: Int, rect: CGSize) -> CGPoint
    func updateHoverStats(touches: [CGPoint])
    func export(_ format: PortfolioExportFormat, onComplete: @escaping (Bool) -> Void)
    func refreshPortfolioData() async
    func refreshImportWallets() async
    func getCoinColors() async
    func calculatePortfolioTotal() async
    func findTransaction(transaction: String) async -> ((any PortfolioEvent)?, Toplist?)
    func setBenchmarkCoin(id: String) async
    func clearBenchmark()
}

@MainActor @Observable
final class PortfolioViewModelImp: PortfolioViewModel, ObservableObject, ChartHoverHosting {
    private var cancellable: Set<AnyCancellable> = []
    
    private(set) var reloading = true
    private(set) var portfolio: [Pie]?
    private(set) var allPrices = [Cryptocurrency]()
    private(set) var scrollToTopActive = false
    
    private(set) var prices = [Double]()
    private(set) var timeStamps = [Double]()
    private var rawPrices = [Double]()
    private var rawTimeStamps = [Double]()
    private(set) var benchmarkCoin: Toplist?
    private(set) var benchmarkPrices = [Double]()
    private(set) var benchmarkTimeStamps = [Double]()
    private var rawBenchmarkPrices = [Double]()
    
    private(set) var changePercent: Double?
    private(set) var changeValue: Double?
    private(set) var graphStats: [String?] = [nil, nil, nil, nil, nil, nil]
    private(set) var chartValues: [String] = []
    
    var holdings = PortfolioHoldingsViewModel()
    var transactions = PortfolioTransactionsViewModel()
    
    // MARK: - Cached Lookups for O(1) Access
    private var pricesByIdCache: [String: [String: Double]] = [:]
    private var transactionAmountsCache: [String: Double] = [:]
    
    var hideData: Bool
    
    var hover = ChartHoverState(valueStyle: .currency(threshold: .billion))
    
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
        hover.hidesValues = hideData
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
            let resolvedDataPies = dataPies.map { pie -> Pie in
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
    
    private var selectedCurrency: CurrencyModel {
        settingsManager.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    }
    
    private func recalculateHoldings() {
        let currency = selectedCurrency
        holdings.recalculate(
            portfolio: portfolio,
            allPrices: allPrices,
            pricesById: pricesByIdCache,
            amountsById: transactionAmountsCache,
            currencyCode: currency.code.lowercased(),
            profitLossCurrencyCode: currency.code
        )
    }
    
    func reloadTransactions() async {
        await transactions.setGroupTransactions(portfolio: portfolio)
    }
    
    func hasBoughtPro() async -> Bool {
        return await storeKitManager.currentSubscription != nil
    }
    
    func toggleHideData() {
        hideData.toggle()
        hover.hidesValues = hideData
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
                let lastPrice = pie.data?.holdingPrice(
                    vsCurrencyPrices: priceCache[coinId],
                    currencyCode: currencyCode
                ) ?? 0
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
            
            return Localization.format("The price was %@ on", price)
        }
    }

    var graphColor: Color {
        hover.graphColor(idle: changePercent?.changeColor ?? .onSurfaceDim)
    }
    
    var changePercentGraph: Double? {
        let chartPrices = rawPrices.filter { $0 != -1 }
        guard let first = chartPrices.first,
              let last = chartPrices.last else {
            return nil
        }
        
        return Double.getDifferenceInPercent(between: last, and: first)?.roundTo(places: 7)
    }
    
    var hoverTimePosition: CGFloat {
        hover.timeLabelX(pointX: point(at: currentHoverIndex, rect: chartSize).x)
    }
    
    var hoverPricePosition: CGFloat {
        hover.priceLabelX(pointX: point(at: currentHoverIndex, rect: chartSize).x)
    }
    
    var mainDragIndex: [Int] {
        hover.linearDragIndices(
            priceCount: getPrices(dropLastTwo: benchmarkCoin != nil).count,
            timestamps: getTimeStamps(dropLastTwo: benchmarkCoin != nil)
        )
    }
    
    private var currentHoverIndex: Int {
        hover.currentLinearIndex(priceCount: getPrices(dropLastTwo: benchmarkCoin != nil).count)
    }
    
    var dragPositions: [CGPoint] {
        hover.linearDragPositions(
            priceCount: getPrices(dropLastTwo: benchmarkCoin != nil).count,
            timestamps: getTimeStamps(dropLastTwo: benchmarkCoin != nil)
        ) { index, size in
            point(at: index, rect: size)
        }
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
        
        hover.updateLinear(
            touches: touches,
            prices: benchmarkCoin == nil ? rawPrices : portfolioHoverPrices,
            dates: getTimeStamps(dropLastTwo: benchmarkCoin != nil),
            timeChart: .aWeek
        )
    }
    
    func export(_ format: PortfolioExportFormat, onComplete: @escaping (Bool) -> Void = { _ in }) {
        guard let portfolio,
              let content = PortfolioExportBuilder.content(for: format, from: portfolio) else {
            onComplete(false)
            return
        }

        shareExport(content: content, format: format, onComplete: onComplete)
    }

    private func shareExport(
        content: String,
        format: PortfolioExportFormat,
        onComplete: @escaping (Bool) -> Void
    ) {
        let fileURL = content.createFile(format.fileName, extensionName: format.fileExtension)

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
            recalculateHoldings()
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
        
        // Run setPrices() and transaction grouping in parallel since they don't depend on each other
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.setPrices() }
            group.addTask { await self.reloadTransactions() }
        }
        
        addExtraElementsToTimeline()
        
        // Set computed values after all data is ready (batch synchronous updates)
        setChangePercent()
        setChangeValue()
        setGraphStats()
        setChartValues()
        recalculateHoldings()

        self.reloading = false
    }
    
    func findTransaction(transaction: String) async -> ((any PortfolioEvent)?, Toplist?) {
        await portfolioRepository.findTransaction(lookup: transaction)
    }
}
