//
//  FearGreedViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-08.
//

import Foundation
import SwiftUI

@MainActor
protocol FearGreedViewModel {
    var isDragging: Bool { get }
    var hoverHelper: HoverHelper { get }
    var chartSize: CGSize { get set }
    var hoverPriceWidthSize: CGFloat { get }
    var hoverTimeWidthSize: CGFloat { get set }
    var historicTimeframes: [(Int, String)] { get }
    var prices: [Double] { get }
    var normalizedPrices: [Double] { get }
    var timeStamps: [Double] { get }
    var fearGreed: FearGreed? { get }
    var timeChart: TimeCharts { get }
    var graphColor: Color { get }
    var dragPositions: [CGPoint] { get }
    var hoverTime: String { get }
    var hoverPrice: String { get }
    var hoverTimePosition: CGFloat { get }
    var hoverPricePosition: CGFloat { get }
    var differenceValue: String { get }
    var differencePercent: String { get }
    var getChangeColor: Color { get }
    
    func setStartData() async
    func getFearGreed() async
    func setTimeChart(_ timeChart: TimeCharts)
    func getHistoricTextAccessible(at index: Int, value: String) -> String
    func updateHoverStats(touches: [CGPoint])
}

@Observable
class FearGreedViewModelImp: FearGreedViewModel {
    var isDragging = false
    var hoverHelper = HoverHelper()
    var chartSize: CGSize = .zero
    var hoverPriceWidthSize: CGFloat = 0.0
    var hoverTimeWidthSize: CGFloat = 0.0
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
    
    private var timer: Timer?

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
        guard hoverHelper.hoverPrices.count == 2, isDragging else {
            return getIndexColor(indexValue: fearGreed?.data?.first?.value ?? "0")
        }
        
        let first = hoverHelper.hoverPrices[safely: 0] ?? 0
        let second = hoverHelper.hoverPrices[safely: 1] ?? 0
        let difference = second - first
        let change = difference.roundTo(places: 7)
        
        if change == 0.0 {
            return Double.getDifferenceInPercent(between: second, and: first)?.changeColor ?? .onSurfaceDim
        } else {
            return change.changeColor
        }
    }
    
    var dragPositions: [CGPoint] {
        let dragPositions = hoverHelper.offset.map({
            (CGFloat(prices.count - 2) / (chartSize.width / $0.x)).safeValue
        }).map({ prices.point(at: Int($0), rect: chartSize, dropCount: 2) })
        
        let newDragPosition = dragPositions.map({ CGPoint(x: $0.x - 0.5, y: $0.y)})
        
        return isDragging ? newDragPosition : [newDragPosition.first ?? .zero]
    }
    
    var hoverTime: String {
        return hoverHelper.hoverTimes.first ?? "0"
    }
    
    var hoverPrice: String {
        return "\(Int(hoverHelper.hoverPrices.first ?? 0))"
    }
    
    var hoverTimePosition: CGFloat {
        return getXPosition(textSize: hoverTimeWidthSize) - hoverTimeWidthSize / 2
    }
    
    var hoverPricePosition: CGFloat {
        return getXPosition(textSize: hoverPriceWidthSize) - hoverTimeWidthSize / 2
    }
    
    var differenceValue: String {
        let first: CGFloat = hoverHelper.hoverPrices[safely: 0] ?? 0
        let second: CGFloat = hoverHelper.hoverPrices[safely: 1] ?? 0.0
        let percent = Double.getDifferenceInPercent(between: second, and: first)?.safeValue ?? 0
        let sign = percent.roundTo(places: 2) < 0 ? "" : "+"
        let difference = Int((hoverHelper.hoverPrices[safely: 1] ?? 0) - (hoverHelper.hoverPrices[safely: 0] ?? 0))
        return "\(sign)\(difference)"
    }
    
    var differencePercent: String {
        let first: CGFloat = hoverHelper.hoverPrices[safely: 0] ?? 0
        let second: CGFloat = hoverHelper.hoverPrices[safely: 1] ?? 0.0
        let difference = Double.getDifferenceInPercent(between: second, and: first) ?? 0
        let sign = difference >= 0 ? "+" : "-"
        
        return "\(sign)\(difference.safeValue.removeZerosFromEnd(force: true).withoutSymbol)%"
    }
    
    var getChangeColor: Color {
        let difference = (hoverHelper.hoverPrices[safely: 1] ?? 0) - (hoverHelper.hoverPrices[safely: 0] ?? 0)
        return difference.roundTo(places: 7).changeColor
    }
    
    // MARK: - Private variables
    
    private var currentHoverIndex: Int {
        guard chartSize.width > 0 else { return 0 }
        
        let offsets = hoverHelper.offset
        let hoverPoint = hoverHelper.hoverPrices.count == 2 ? offsets.map({ $0.x }).reduce(0, +) / 2 : offsets.first?.x ?? 0
        
        return Int(CGFloat(prices.count - 2) / (chartSize.width / hoverPoint))
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
        guard !timeStamps.isEmpty, !touches.isEmpty else {
            isDragging = false
            timer?.invalidate()
            return
        }
        
        if !isDragging {
            timer?.invalidate()
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { _ in
                Task { @MainActor in
                    self.isDragging = !touches.isEmpty
                    
                    if self.isDragging {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            })
        }
        
        hoverHelper.offset = touches.map({
            CGPoint(x: max(0, min($0.x, chartSize.width.rounded(.down) - 0.00001)), y: $0.y)
        })
        
        hoverHelper.getHoverPrice(
            readerSize: chartSize,
            offset: hoverHelper.offset,
            prices: prices.dropLast(2),
            dates: timeStamps,
            timeChart: timeChart,
            inFearGreedView: true,
            isDragging: isDragging
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
    
    private func getXPosition(textSize: CGFloat) -> CGFloat {
        let xPoint = prices.point(at: currentHoverIndex, rect: chartSize, dropCount: 2).x
        return getPriceXPosition(position: xPoint, textSize: textSize, readerWidthSize: chartSize.width)
    }
    
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
