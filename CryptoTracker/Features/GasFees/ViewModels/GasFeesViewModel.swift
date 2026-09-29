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
protocol GasFeesViewModel: ChartHoverHosting {
    var gasFees: GasFees? { get }
    var gasFeePrices: GasFees? { get }
    var ethereum: Toplist? { get }
    
    func setStartData() async

    var prices: [Double] { get }
    var allPrices: [Double] { get }
    var timeStamps: [Double] { get }
    var historicTimeframes: [(Int, String)] { get }
    var currentTimeFrames: [(String?, String)] { get }
    var graphColor: Color { get }
    var dragPositions: [CGPoint] { get }
    var hoverTimePosition: CGFloat { get }
    var hoverPricePosition: CGFloat { get }
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
class GasFeesViewModelImp: GasFeesViewModel, ChartHoverHosting {
    private let gasFeesRepository: GasFeesRepository
    private let toplistRepository: ToplistRepository
    private let cryptoDetailRepository: CryptoDetailRepository

    var gasFees: GasFees?
    var gasFeePrices: GasFees?
    var ethereum: Toplist?
    
    var hover = ChartHoverState(valueStyle: .decimal(fractionLength: 2))
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
    
    // MARK: - Variables
    
    var graphColor: Color {
        hover.graphColor(idle: getGasIndexColor(indexValue: gasFeePrices?.gasFeeData?.first?.proposeGasPrice ?? "0"))
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
        let amount = Double(value)?.numberAccessible(maxPlaces: 3) ?? "0"
        let unit = Localization.string("Gwei")
        let key: String
        
        switch index {
        case 0:
            key = "The current low Ethereum gas fee is %@ %@"
        case 1:
            key = "The current average Ethereum gas fee is %@ %@"
        default:
            key = "The current high Ethereum gas fee is %@ %@"
        }
        
        return Localization.format(key, amount, unit)
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
        hover.updateLinear(
            touches: touches,
            prices: Array(prices.dropLast(2)),
            dates: timeStamps,
            timeChart: .aWeek,
            inFearGreedView: true
        )
    }
    
    // MARK: - Private functions
    
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
