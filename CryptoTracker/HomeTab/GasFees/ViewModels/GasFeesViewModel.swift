//
//  GasFeesViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-09.
//

import Foundation
import SwiftUI

enum GasUnits: Double {
    case swap = 356_190
    case nft = 601_954
    case bridging = 114_556
    case borrowing = 302_169
}

@MainActor
protocol GasFeesViewModel {
    var gasFees: GasFees? { get }
    var gasFeePrices: GasFees? { get }
    var ethereum: Toplist? { get }
    
    func setStartData() async

    var isDragging: Bool { get }
    var hoverHelper: HoverHelper { get }
    var chartSize: CGSize { get set }
    var hoverPriceWidthSize: CGFloat { get set }
    var hoverTimeWidthSize: CGFloat { get set }
    var prices: [Double] { get }
    var allPrices: [Double] { get }
    var timeStamps: [Double] { get }
    var historicTimeframes: [(Int, String)] { get }
    var currentTimeFrames: [(String?, String)] { get }
    var graphColor: Color { get }
    var dragPositions: [CGPoint] { get }
    var hoverTime: String { get }
    var hoverPrice: String { get }
    var hoverTimePosition: CGFloat { get }
    var hoverPricePosition: CGFloat { get }
    var differenceValue: String { get }
    var differencePercent: String { get }
    var getChangeColor: Color { get }
    var graphStats: [String?] { get }
    
    func getGasFees() async
    func getGasFeePrices() async
    func getEthereumPrice() async
    func getGasPrice(for gasUnit: GasUnits, accessible: Bool) -> String?
    func getHistoricTextAccessible(at index: Int, value: String) -> String
    func getCurrentTextAccessible(at index: Int, value: String) -> String
    func normalizedPosition(for value: Double) -> Double
    func updateHoverStats(touches: [CGPoint])
}

@MainActor @Observable
class GasFeesViewModelImp: GasFeesViewModel {
    private let gasFeesRepository: GasFeesRepository
    private let toplistRepository: ToplistRepository
    private let cryptoDetailRepository: CryptoDetailRepository

    var gasFees: GasFees?
    var gasFeePrices: GasFees?
    var ethereum: Toplist?
    
    var isDragging = false
    var hoverHelper = HoverHelper()
    var chartSize: CGSize = .zero
    var hoverPriceWidthSize: CGFloat = 0.0
    var hoverTimeWidthSize: CGFloat = 0.0
    var prices = [Double]()
    var allPrices = [Double]()
    var timeStamps = [Double]()
    
    var currentTimeFrames: [(String?, String)] {
        [
            (gasFees?.gasFeeData?.first?.safeGasPrice, "Current Low"),
            (gasFees?.gasFeeData?.first?.proposeGasPrice, "Current Average"),
            (gasFees?.gasFeeData?.first?.fastGasPrice, "Current High")
        ]
    }

    var historicTimeframes: [(Int, String)] {
        [
            (0, "Today"),
            (1, "Yesterday"),
            (7, "Last week"),
            (30, "Last month")
        ]
    }
    
    private var timer: Timer?
    
    init(
        gasFeesRepository: GasFeesRepository = GasFeesRepositoryImp.shared,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared
    ) {
        self.gasFeesRepository = gasFeesRepository
        self.toplistRepository = toplistRepository
        self.cryptoDetailRepository = cryptoDetailRepository
    }
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await toplistRepository.ensureCacheLoaded()
        await gasFeesRepository.ensureCacheLoaded()
        
        if let data = await gasFeesRepository.cachedGasFees?.data {
            self.gasFees = data
        }
        
        if let prices = await gasFeesRepository.cachedGasFeePrices?.data {
            self.gasFeePrices = prices
            setPrices()
        }
        
        if let toplist = await toplistRepository.cachedSmallToplist?.data, let ethereum = toplist.first(where: { $0.id == "ethereum"}) {
            self.ethereum = ethereum
        }
    }
    
    // MARK: - Private variables
    
    private var currentHoverIndex: Int {
        guard chartSize.width > 0 else { return 0 }
        
        let offsets = hoverHelper.offset
        let hoverPoint = hoverHelper.hoverPrices.count == 2 ? offsets.map({ $0.x }).reduce(0, +) / 2 : offsets.first?.x ?? 0
        
        return Int(CGFloat(prices.count - 2) / (chartSize.width / hoverPoint))
    }
    
    // MARK: - Variables
    
    var graphColor: Color {
        guard hoverHelper.hoverPrices.count == 2, isDragging else {
            return getGasIndexColor(indexValue: gasFeePrices?.gasFeeData?.first?.proposeGasPrice ?? "0")
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
        return "\(hoverHelper.hoverPrices.first?.formatted(.number.precision(.fractionLength(2))) ?? "0")"
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
        let difference = (hoverHelper.hoverPrices[safely: 1] ?? 0) - (hoverHelper.hoverPrices[safely: 0] ?? 0)
        let formattedDifference = difference.formatted(.number.precision(.fractionLength(2)))
        return "\(sign)\(formattedDifference)"
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
    
    var graphStats: [String?] {
        return (0..<6).map {
            guard let minPrice = prices.min(),
                  let maxPrice = prices.max() else {
                      return nil
                  }
            
            let step = (maxPrice - minPrice) / 5
            let value = minPrice + (step * Double($0))
            
            return value.formatCurrency(
                currency: CurrencyModel.empty,
                maxDecimals: 0
            )
        }
    }

    func getGasFees() async {
        if let gasFees = await gasFeesRepository.getGasFees() {
            self.gasFees = gasFees
        }
    }
    
    func getGasFeePrices() async {
        if let prices = await gasFeesRepository.getGasFeePrices() {
            self.gasFeePrices = prices
            setPrices()
        }
    }
    
    func getEthereumPrice() async {
        if let toplist = await toplistRepository.getSmallToplist(), let ethereum = toplist.first(where: { $0.id == "ethereum" }) {
            self.ethereum = ethereum
        }
    }
    
    func getGasPrice(for gasUnit: GasUnits, accessible: Bool) -> String? {
        guard let gasPrice = gasFees?.gasFeeData?.first?.proposeGasPrice,
              let averageGasPrice = Double(gasPrice),
              let ethPrice = ethereum?.current_price else { return nil }
        
        let gasUnits = gasUnit.rawValue
        let cost = (averageGasPrice / 1_000_000_000) * gasUnits * ethPrice
        
        if accessible {
            return cost.formatCurrency(maxDecimals: 2, accessible: true)
        } else {
            return cost.formatCurrency(maxDecimals: 2)
        }
    }
    
    func getHistoricTextAccessible(at index: Int, value: String) -> String {
        let formattedValue = Double(value)?.numberAccessible(maxPlaces: 2) ?? "0"
        
        if index == 0 {
            return "The current average ethereum gas fee is \(formattedValue) Gwei"
        } else {
            let currentTimeframe = historicTimeframes[safely: index]?.1 ?? ""
            return "The average ethereum gas fee was \(formattedValue) \(index == 0 ? "" : currentTimeframe)."
        }
    }
    
    func getCurrentTextAccessible(at index: Int, value: String) -> String {
        return "The \(currentTimeFrames[index].1) ethereum gas fee is \(Double(value)?.numberAccessible(maxPlaces: 3) ?? "0") Gwei"
    }

    func normalizedPosition(for value: Double) -> Double {
        let segments: [(start: Double, end: Double)] = [
            (0, 3),
            (3, 10),
            (10, 30),
            (30, 80),
            (80, 100)
        ]
        
        let segmentWidth = 1.0 / Double(segments.count)
        
        for (index, segment) in segments.enumerated() {
            if value >= segment.start && value <= segment.end {
                let range = segment.end - segment.start
                let localProgress = (value - segment.start) / range
                return Double(index) * segmentWidth + localProgress * segmentWidth
            }
        }
        
        // Clamp values outside range
        if let first = segments.first, value < first.start { return 0.0 }
        if let last = segments.last, value > last.end { return 1.0 }
        
        return 0.0
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
            timeChart: .aWeek,
            inFearGreedView: true,
            isDragging: isDragging
        )
    }
    
    // MARK: - Private functions
    
    private func getXPosition(textSize: CGFloat) -> CGFloat {
        let xPoint = prices.point(at: currentHoverIndex, rect: chartSize, dropCount: 2).x
        return getPriceXPosition(position: xPoint, textSize: textSize, readerWidthSize: chartSize.width)
    }
    
    private func setPrices() {
        guard let data = gasFeePrices?.gasFeeData, !data.isEmpty else { return }
        
        let array: [GasResult] = Array(data.prefix(7))
        var cgFloatArray = [Double]()
        var doubleArray = [Double]()
        
        cgFloatArray = array.reversed().map({ Double($0.proposeGasPrice) ?? 0 })
        cgFloatArray.append(contentsOf: [0.0, 10])
        
        doubleArray = array.reversed().map({ Double(($0.sK_Date.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)?.timeIntervalSince1970 ?? 0) * 1000) })
        
        prices = cgFloatArray
        timeStamps = doubleArray
        allPrices = data.map({ Double($0.proposeGasPrice) ?? 0 })
    }
}
