//
//  GlobalMarketViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-09.
//

import Foundation
import Combine
import UIKit
import SwiftUI

@MainActor
protocol GlobalMarketViewModel {
    var globalMarket: GlobalMarketModel? { get }
    var globalMarketChart: GlobalMarketChartData? { get }
    var selectedTimeFrame: TimeCharts { get set }
    var selectedChartType: ChartTypes { get set }
    var prices: [Double] { get set }
    var timeStamps: [Double] { get set }
    var changePercent: Double? { get }
    var reloading: Bool { get set }
    var showMainPriceError: Bool { get set }
    var hoverHelper: HoverHelper { get set }
    var hoverTimeWidthSize: CGFloat { get set }
    var chartSize: CGSize { get set }
    var isDragging: Bool { get set }
    var mainGraphStats: [String?] { get }
    var differenceValue: String { get }
    var differencePercent: String { get }
    var graphColor: Color { get }
    var hoverTime: String { get }
    var hoverPrice: String { get }
    var hoverTimePosition: CGFloat { get }
    var dragPositions: [CGPoint] { get }
    var latestChartMarketCap: Double? { get }
    var latestChartVolume: Double? { get }
    
    func setStartData() async
    func getGlobalMarket() async
    func refresh(newDays: String?, newTimeChart: TimeCharts?) async
    func setChartType(type: ChartTypes)
    func getPrices() -> [Double]
    func getTimestamps() -> [Double]
    func setPrices()
    func setTimestamps()
    func updateHoverStats(touches: [CGPoint])
    func getColors() async
}

@Observable
class GlobalMarketViewModelImp: GlobalMarketViewModel {
    private let globalMarketRepository: GlobalMarketRepository
    
    private var timer: Timer?

    var globalMarket: GlobalMarketModel?
    var globalMarketChart: GlobalMarketChartData?
    var selectedTimeFrame = TimeCharts.getStartTimeFrame(between: .aWeek, and: .max)
    var selectedChartType: ChartTypes = {
        let saved: ChartTypes = SettingsManager.shared.get(key: AppSettingKey.graphType) ?? .mktCap
        return saved == .price ? .mktCap : saved
    }()
    var prices = [Double]()
    var timeStamps = [Double]()
    private(set) var changePercent: Double?
    var reloading = true
    var showMainPriceError = false
    var hoverHelper = HoverHelper()
    var hoverTimeWidthSize: CGFloat = 0
    var chartSize: CGSize = .zero
    var isDragging = false

    init(globalMarketRepository: GlobalMarketRepository = GlobalMarketRepositoryImp.shared) {
        self.globalMarketRepository = globalMarketRepository
    }
    
    var mainGraphStats: [String?] {
        (0..<6).map { getPriceInChart(prices: getPrices(), at: $0) }
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
    
    var hoverTime: String {
        hoverHelper.hoverTimes.first ?? "0"
    }
    
    var hoverPrice: String {
        hoverHelper.hoverPrices.first?.formatCurrency(threshold: FormattingThreshold.million) ?? "0"
    }
    
    var hoverTimePosition: CGFloat {
        getXPosition(textSize: hoverTimeWidthSize) - hoverTimeWidthSize / 2
    }
    
    var dragPositions: [CGPoint] {
        mainDragIndex.map {
            point(at: $0, rect: CGSize(width: chartSize.width, height: chartSize.height))
        }
    }
    
    var latestChartMarketCap: Double? {
        lastChartValue(in: globalMarketChart?.market_cap)
    }
    
    var latestChartVolume: Double? {
        lastChartValue(in: globalMarketChart?.volume)
    }
    
    private var mainDragIndex: [Int] {
        let pricesCount = CGFloat(getPrices().count)
        let firstTimestamp = timeStamps.normalized.first ?? 0
        let timestampCount = Double(getTimestamps().count)
        
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
    
    func setStartData() async {
        await globalMarketRepository.ensureCacheLoaded()
        
        if let data = await globalMarketRepository.cachedGlobalMarket?.data {
            self.globalMarket = data
        }
        
        if let data = await globalMarketRepository.cachedGlobalChart?.data?.market_cap_chart {
            self.globalMarketChart = data
            setPrices()
            setTimestamps()
            showMainPriceError = prices.isEmpty
        }
    }

    func getGlobalMarket() async {
        if let globalMarket = await globalMarketRepository.getGlobalMarket() {
            self.globalMarket = globalMarket
        }
    }
    
    func refresh(newDays: String? = nil, newTimeChart: TimeCharts? = nil) async {
        reloading = true
        
        let chart = newTimeChart ?? selectedTimeFrame
        selectedTimeFrame = chart
        
        if let globalMarketChart = await globalMarketRepository.getGlobalChart(days: newDays ?? chart.days) {
            self.globalMarketChart = globalMarketChart
            setPrices()
            setTimestamps()
            showMainPriceError = false
        } else {
            showMainPriceError = true
        }
        
        reloading = false
    }
    
    func getColors() async {
        for await globalMarket in await globalMarketRepository.getColors() {
            self.globalMarket = globalMarket
        }
    }
    
    func setChartType(type: ChartTypes) {
        selectedChartType = type
        SettingsManager.shared.set(data: selectedChartType, key: AppSettingKey.graphType)
        
        setPrices()
        setTimestamps()
        showMainPriceError = prices.isEmpty
    }
    
    func getPrices() -> [Double] {
        prices
    }
    
    func getTimestamps() -> [Double] {
        timeStamps
    }
    
    func setPrices() {
        let chartData: [[Double?]]? = switch selectedChartType {
        case .volume:
            globalMarketChart?.volume
        default:
            globalMarketChart?.market_cap
        }
        
        prices = chartData?
            .compactMap { $0.last ?? 0 }
            .filter { $0 != 0 } ?? []
        
        changePercent = Double.getDifferenceInPercent(between: prices.last, and: prices.first)
    }
    
    func setTimestamps() {
        let chartData: [[Double?]]? = switch selectedChartType {
        case .volume:
            globalMarketChart?.volume
        default:
            globalMarketChart?.market_cap
        }
        
        timeStamps = chartData?
            .compactMap { $0.first ?? 0 }
            .filter { $0 != 0 } ?? []
    }
    
    func updateHoverStats(touches: [CGPoint]) {
        guard !reloading else { return }
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
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
    
    private func lastChartValue(in chartData: [[Double?]]?) -> Double? {
        chartData?
            .compactMap { $0.last ?? 0 }
            .filter { $0 != 0 }
            .last
    }
    
    private func getPriceInChart(prices: [Double], at index: Int) -> String? {
        guard !showMainPriceError,
              let minPrice = prices.min(),
              let maxPrice = prices.max() else {
            return nil
        }
        
        let step = (maxPrice - minPrice) / 5
        let value = minPrice + (step * Double(index))
        
        return value.formatCurrency(currency: CurrencyModel.empty)
    }
    
    private func point(at index: Int, rect: CGSize) -> CGPoint {
        let normalizedPrices = getPrices().normalized
        let pointValue = normalizedPrices[safely: index] ?? 0
        
        let denominator = Double(normalizedPrices.count - 1)
        let x = rect.width * Double(index) / denominator
        let y = (1 - pointValue) * rect.height
        
        return CGPoint(
            x: x - 0.5,
            y: y.isNaN ? 0.5 * rect.height : y
        )
    }
    
    private func getXPosition(textSize: CGFloat) -> CGFloat {
        let xPoint = getPrices().point(at: currentHoverIndex, rect: chartSize).x
        return getPriceXPosition(position: xPoint, textSize: textSize, readerWidthSize: chartSize.width)
    }
    
    private var currentHoverIndex: Int {
        guard chartSize.width > 0 else { return 0 }
        
        let hoverPoints = hoverHelper.offset.map(\.x)
        let hoverPoint: CGFloat
        
        if hoverHelper.hoverPrices.count == 2 {
            hoverPoint = hoverPoints.reduce(0, +) / 2
        } else {
            hoverPoint = hoverPoints.first ?? 0
        }
        
        return chartLinearSeriesIndex(x: hoverPoint, width: chartSize.width, pointCount: getPrices().count)
    }
}
