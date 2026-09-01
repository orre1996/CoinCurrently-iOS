//
//  File.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-01-13.
//

import Foundation
import SwiftUI

struct CurrentChartHover {
    var time: String
    var open: Double
    var high: Double
    var low: Double
    var close: Double
}

@Observable @MainActor
class HoverHelper {
#if IS_APP
    let impactMed = UIImpactFeedbackGenerator(style: .light)
#endif
    
    var hoverPrices = [Double]()
    var SMAHoverPrices = [Double]()
    var hoverTimes = [String]()
    var currentCandle: CurrentChartHover?
    var offset = [CGPoint]()
    var dateFormatter: DateFormatter = DateFormatter()
    var tempHoverTimes = [String]()
    
    var compareHoverPrice = 0.0
    var latestPositions = [Int]()
    var latestComparePosition = 0
    
    init() {
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
    }
    
    func resetValues() {
        offset = []
        hoverPrices = []
        hoverTimes = []
    }
    
    func getHoverPrice(readerSize: CGSize, offset: [CGPoint], prices: [Double], dates: [Double], timeChart: TimeCharts?, compareDates: [Double]? = nil, comparePrices: [Double]? = nil, inFearGreedView: Bool = false, isDragging: Bool) {
        // Pre-compute loop-invariant values
        let mainMinTime = dates.lazy.filter { $0 != -1 }.min() ?? .infinity
        let compareMinTime = compareDates?.lazy.filter { $0 != -1 }.min() ?? .infinity
        let lowestTimeStamp = mainMinTime < compareMinTime ? dates : (compareDates ?? [])
        
        let offsetCount = offset.count
        var indices = [Int]()
        var localPricesArray = [Double]()
        var localTimes = [String]()
        var temporaryTimes = [String]()
        
        indices.reserveCapacity(offsetCount)
        localPricesArray.reserveCapacity(offsetCount)
        localTimes.reserveCapacity(offsetCount)
        temporaryTimes.reserveCapacity(offsetCount)

        // First pass: compute indices and prices (match line charts: x = width * i / (n - 1))
        for point in offset {
            let index = chartLinearSeriesIndex(x: point.x, width: readerSize.width, pointCount: prices.count)
            indices.append(index)
            localPricesArray.append(prices[safely: index] ?? 0.0)
        }
        
        // Second pass: format hover times (one dateFormat set)
        dateFormatter.dateFormat = getHoverDateFormat(timeChart: timeChart, dontShowTime: inFearGreedView)
        for index in indices {
            let date = Date(timeIntervalSince1970: (lowestTimeStamp[safely: index] ?? 0.0) / 1000)
            localTimes.append(dateFormatter.string(from: date))
        }
        
        // Third pass: format temporary times (one dateFormat set)
        let timeSuffix = Date.uses24HourClock ? "HH:mm" : "hh:mm a"
        dateFormatter.dateFormat = "dd MMM 'at' \(timeSuffix)"
        for index in indices {
            let date = Date(timeIntervalSince1970: (lowestTimeStamp[safely: index] ?? 0.0) / 1000)
            temporaryTimes.append(dateFormatter.string(from: date))
        }

        if tempHoverTimes != temporaryTimes && isDragging {
            hapticFeedback()
        }
        
        tempHoverTimes = temporaryTimes
        hoverPrices = localPricesArray
        hoverTimes = localTimes
    }
    
    func getCompareHoverPrice(readerSize: CGSize, offset: CGPoint, prices: [Double], dates: [Double], timeChart: TimeCharts?) {
        let index = chartLinearSeriesIndex(x: offset.x, width: readerSize.width, pointCount: prices.count)
        compareHoverPrice = prices[safely: index] ?? 0.0
    }
    
    func getHoverDateFormat(timeChart: TimeCharts?, dontShowTime: Bool = false) -> String {
        let timeSuffix = Date.uses24HourClock ? "HH:mm" : "hh:mm a"
        
        switch timeChart {
        case .aWeek:
            return dontShowTime ? "MMM dd, YYYY" : "MMM dd 'at' \(timeSuffix)"
        case .aMonth, .threeMonths, .aYear:
            return "MMM dd, YYYY"
        case .max:
            return "MMM YYYY"
        default:
            return "MMM dd 'at' \(timeSuffix)"
        }
    }
    
    func getTimeOnHover(index: Int, dates: [Double], timeChart: TimeCharts?, dontShowTime: Bool = false) -> String {
        let date = Date(timeIntervalSince1970: (dates[safely: index] ?? 0.0) / 1000)
        dateFormatter.dateFormat = getHoverDateFormat(timeChart: timeChart, dontShowTime: dontShowTime)
        return dateFormatter.string(from: date)
    }
    
    func getTemporaryTimeOnHover(index: Int, dates: [Double]) -> String {
        let date = Date(timeIntervalSince1970: (dates[safely: index] ?? 0.0) / 1000)
        dateFormatter.dateFormat = "dd MMM 'at' \(Date.uses24HourClock ? "HH:mm" : "hh:mm a")"
        return dateFormatter.string(from: date)
    }
    
    func getHoverPriceExchange(readerSize: CGSize, offset: [CGPoint], prices: [Double], dates: [Double], timeChart: TimeCharts?, isDragging: Bool) {
        guard readerSize != .zero else { return }

        let offsetCount = offset.count
        
        var localPricesArray = [Double]()
        var localTimes = [String]()
        var tempPositions = [Int]()
        
        localPricesArray.reserveCapacity(offsetCount)
        localTimes.reserveCapacity(offsetCount)
        tempPositions.reserveCapacity(offsetCount)
        
        // First pass: compute positions and prices
        for point in offset {
            let position = chartLinearSeriesIndex(x: point.x, width: readerSize.width, pointCount: prices.count)
            tempPositions.append(position)
            localPricesArray.append(prices[safely: position] ?? 0.0)
        }
        
        // Second pass: format times (one dateFormat set)
        dateFormatter.dateFormat = getExchangeDateFormat(timeChart: timeChart)
        for position in tempPositions {
            let date = Date(timeIntervalSince1970: (dates[safely: position] ?? 0.0) / 1000)
            localTimes.append(dateFormatter.string(from: date))
        }
    
        if latestPositions != tempPositions && isDragging {
            hapticFeedback()
        }

        latestPositions = tempPositions
        hoverPrices = localPricesArray
        hoverTimes = localTimes
    }
    
    func getExchangeDateFormat(timeChart: TimeCharts?) -> String {
        let timeSuffix = Date.uses24HourClock ? "HH:mm" : "hh:mm a"
        
        switch timeChart {
        case .aDay, .aWeek:
            return "MMM dd 'at' \(timeSuffix)"
        case .aMonth, .aYear:
            return "MMM dd, YYYY"
        case .max:
            return "MMM YYYY"
        default:
            return "dd MMM 'at' \(timeSuffix)"
        }
    }
    
    func getTimeOnHoverExchange(readerSize: CGSize, offset: CGPoint, prices: [Double], dates: [Double], timeChart: TimeCharts?) -> String {
        let position = chartLinearSeriesIndex(x: offset.x, width: readerSize.width, pointCount: prices.count)
        
        let date = Date(timeIntervalSince1970: (dates[safely: position] ?? 0.0) / 1000)
        dateFormatter.dateFormat = getExchangeDateFormat(timeChart: timeChart)
        return dateFormatter.string(from: date)
    }
    
    func getHoverPriceCandles(readerSize: CGSize, offset: CGPoint, prices: [Candle]?, timeChart: TimeCharts?, isDragging: Bool, volumes: [Double]) {
        guard let prices else { return }

        let position = candleBinIndex(x: offset.x, width: readerSize.width, candleCount: prices.count)
        let date = getTimeOnHoverCandle(position: position, prices: prices, timeChart: timeChart)
        
        let candle = prices[safely: position]
        currentCandle = CurrentChartHover(
            time: date,
            open: candle?.open ?? 0.0,
            high: candle?.high ?? 0.0,
            low: candle?.low ?? 0.0,
            close: candle?.close ?? 0.0
        )
        
        if latestPositions.first != position && isDragging {
            hapticFeedback()
        }
        
        latestPositions = [position]
        
        getVolumePrices(readerSize: readerSize, offset: offset, volumes: volumes.getTrimmedVolume)
    }
    
    func getVolumePrices(readerSize: CGSize, offset: CGPoint, volumes: [Double]) {
        let position = candleBinIndex(x: offset.x, width: readerSize.width, candleCount: volumes.count)
        hoverPrices = [volumes[safely: position] ?? 0]
    }
    
    func getTimeOnHoverCandle(position: Int, prices: [Candle], timeChart: TimeCharts?) -> String {
        let date = Date(timeIntervalSince1970: (prices[safely: position]?.timestamp ?? 0.0) / 1000)
        dateFormatter.dateFormat = getHoverDateFormat(timeChart: timeChart)
        return dateFormatter.string(from: date)
    }
    
    private func hapticFeedback() {
#if IS_APP
        impactMed.impactOccurred()
#endif
    }
}

// MARK: - Chart index ↔ touch (keep in sync with `calculatePoint` / `ChartLineShape`)

/// Index for line/area charts where point `i` is at `x = width * i / (pointCount - 1)`.
func chartLinearSeriesIndex(x: CGFloat, width: CGFloat, pointCount: Int) -> Int {
    guard pointCount > 0, width > 0 else { return 0 }
    if pointCount == 1 { return 0 }
    let clampedX = min(max(x, 0), width)
    let maxIndex = pointCount
    return min(maxIndex, Int(Double(maxIndex) * Double(clampedX / width)))
}

/// Index under touch for candle charts drawn with equal-width bins (`width / count` per candle).
func candleBinIndex(x: CGFloat, width: CGFloat, candleCount: Int) -> Int {
    guard candleCount > 0, width > 0 else { return 0 }
    if candleCount == 1 { return 0 }
    let safeX = min(max(x, 0), width * (1 - .ulpOfOne))
    let binWidth = width / CGFloat(candleCount)
    return min(candleCount, max(0, Int(safeX / binWidth)))
}

/// Data index for an axis label in column `labelIndex` of `labelCount` (1-based slots, centers like `ChartTimeStamps`).
func getPriceXPosition(position: CGFloat, textSize: CGFloat, readerWidthSize: CGFloat) -> CGFloat {
    if position < textSize / 2 {
        return textSize / 2
    }

    if position + textSize / 2 > readerWidthSize {
        return readerWidthSize - textSize / 2
    }

    return position
}

func chartAxisTimestampIndex(labelIndex: Int, labelCount: Int, dataCount: Int) -> Int {
    guard dataCount > 0 else { return 0 }
    if dataCount == 1 { return 0 }
    let fraction = (Double(labelIndex) - 0.5) / Double(labelCount)
    let clamped = min(1, max(0, fraction))
    let maxIndex = dataCount
    return min(maxIndex, Int(Double(maxIndex) * clamped))
}
