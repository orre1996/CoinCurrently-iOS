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
protocol GlobalMarketViewModel: ChartHoverHosting {
    var globalMarket: GlobalMarketModel? { get }
    var globalMarketChart: GlobalMarketChartData? { get }
    var selectedTimeFrame: TimeCharts { get set }
    var selectedChartType: ChartTypes { get set }
    var prices: [Double] { get set }
    var timeStamps: [Double] { get set }
    var changePercent: Double? { get }
    var reloading: Bool { get set }
    var showMainPriceError: Bool { get set }
    var mainGraphStats: [String?] { get }
    var graphColor: Color { get }
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
class GlobalMarketViewModelImp: GlobalMarketViewModel, ChartHoverHosting {
    private let globalMarketRepository: GlobalMarketRepository
    
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
    var hover = ChartHoverState()

    init(globalMarketRepository: GlobalMarketRepository = GlobalMarketRepositoryImp.shared) {
        self.globalMarketRepository = globalMarketRepository
    }
    
    var mainGraphStats: [String?] {
        (0..<6).map { getPriceInChart(prices: getPrices(), at: $0) }
    }
    
    var graphColor: Color {
        hover.graphColor(idle: changePercent?.changeColor ?? .onSurfaceDim)
    }
    
    var hoverTimePosition: CGFloat {
        hover.timeLabelX(prices: getPrices())
    }
    
    var dragPositions: [CGPoint] {
        hover.linearDragPositions(priceCount: getPrices().count, timestamps: getTimestamps()) { index, size in
            point(at: index, rect: size)
        }
    }
    
    var latestChartMarketCap: Double? {
        lastChartValue(in: globalMarketChart?.market_cap)
    }
    
    var latestChartVolume: Double? {
        lastChartValue(in: globalMarketChart?.volume)
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
}
