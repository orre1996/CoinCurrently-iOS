//
//  FearGreedViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-08.
//

import Foundation
import SwiftUI

@MainActor
protocol FearGreedViewModel: ChartHoverHosting {
    var historicTimeframes: [(Int, String)] { get }
    var prices: [Double] { get }
    var normalizedPrices: [Double] { get }
    var timeStamps: [Double] { get }
    var fearGreed: FearGreed? { get }
    var timeChart: TimeCharts { get }
    var graphColor: Color { get }
    var dragPositions: [CGPoint] { get }
    var hoverTimePosition: CGFloat { get }
    var hoverPricePosition: CGFloat { get }
    var getChangeColor: Color { get }
    
    func setStartData() async
    func getFearGreed() async
    func setTimeChart(_ timeChart: TimeCharts)
    func getHistoricTextAccessible(at index: Int, value: String) -> String
    func updateHoverStats(touches: [CGPoint])
}

@Observable
class FearGreedViewModelImp: FearGreedViewModel, ChartHoverHosting {
    var hover = ChartHoverState(valueStyle: .integer)
    var historicTimeframes = [(0, "Today"), (1, "Yesterday"), (7, "Last week"), (30, "Last month")]
    var prices = [Double]()
    var normalizedPrices = [Double]()
    var timeStamps = [Double]()
    var fearGreed: FearGreed?
    var timeChart = TimeCharts.getStartTimeFrame(between: .aWeek, and: .max) {
        didSet {
            setPrices()
        }
    }
    
    private let fearGreedRepository: FearGreedRepository
    
    init(fearGreedRepository: FearGreedRepository = FearGreedRepositoryImp.shared) {
        self.fearGreedRepository = fearGreedRepository
    }
    
    func setStartData() async {
        await fearGreedRepository.ensureCacheLoaded()
        if let fearGreed = await fearGreedRepository.cachedFearGreed?.data {
            self.fearGreed = fearGreed
            setPrices()
        }
    }
    
    // MARK: - Variables
    
    var graphColor: Color {
        hover.graphColor(idle: getIndexColor(indexValue: fearGreed?.data?.first?.value ?? "0"))
    }
    
    var dragPositions: [CGPoint] {
        hover.paddedDragPositions(prices: prices, dropCount: 2)
    }
    
    var hoverTimePosition: CGFloat {
        hover.timeLabelX(prices: prices, dropCount: 2)
    }
    
    var hoverPricePosition: CGFloat {
        hover.priceLabelX(prices: prices, dropCount: 2)
    }
    
    var getChangeColor: Color {
        hover.rangeChangeColor
    }
    
    // MARK: - Functions
    
    func getFearGreed() async {
        if let fearGreed = await fearGreedRepository.getFearGreed() {
            self.fearGreed = fearGreed
        }
    }
    
    func setTimeChart(_ timeChart: TimeCharts) {
        self.timeChart = timeChart
    }

    func updateHoverStats(touches: [CGPoint]) {
        hover.updateLinear(
            touches: touches,
            prices: Array(prices.dropLast(2)),
            dates: timeStamps,
            timeChart: timeChart,
            inFearGreedView: true
        )
    }
    
    func getHistoricTextAccessible(at index: Int, value: String) -> String {
        if index == 0 {
            return "The fear and greed index is currently \(value) out of 100"
        } else {
            let currentTimeframe = historicTimeframes[safely: index]?.1 ?? ""
            return "The fear and greed index was \(value) out of 100 \(index == 0 ? "" : currentTimeframe)"
        }
    }
    
    // MARK: - Private functions
    
    private func setPrices() {
        guard let data = fearGreed?.data, !data.isEmpty else { return  }
        
        let divider = max(1, data.count / 400)
    
        var array = [FearGreedItem]()
        var cgFloatArray = [Double]()
        var doubleArray = [Double]()
        
        switch timeChart {
        case .aWeek:
            array = Array(data.prefix(7))
            
        case .aMonth:
            array =  Array(data.prefix(30))
            
        case .threeMonths:
            array = Array(data.prefix(90))
            
        case .aYear:
            array = Array(data.prefix(365))
            
        case .max:
            let max = data.compactMap { $0.value?.intValue }.max() ?? 0
            let min = data.compactMap { $0.value?.intValue }.min() ?? 0
            
            array = data.enumerated().compactMap { index, element in
                index % divider == 0 || element.value?.intValue == max || element.value?.intValue == min ? element : nil
            }
            
        default:
            array = []
        }
        
        cgFloatArray = array.reversed().map({ Double(Int($0.value ?? "0") ?? 0) })
        cgFloatArray.append(contentsOf: [0.0, 100])
        
        doubleArray = array.reversed().map({ Double((Int($0.timestamp ?? "0") ?? 0) * 1000) })
        
        prices = cgFloatArray
        timeStamps = doubleArray
        normalizedPrices = cgFloatArray.normalized.dropLast(2)
    }
}
