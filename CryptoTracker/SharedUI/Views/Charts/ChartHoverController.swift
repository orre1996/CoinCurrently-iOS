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
class ChartHoverController {
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
        applyDisplayLocale()
    }
    
    private var localizedAt: String {
        #if IS_APP
        Localization.string("at").replacingOccurrences(of: "'", with: "''")
        #else
        "at"
        #endif
    }
    
    private func applyDisplayLocale() {
        #if IS_APP
        let locale = Localization.locale
        dateFormatter.locale = locale
        let symbols = DateFormatter()
        symbols.locale = locale
        dateFormatter.amSymbol = symbols.amSymbol
        dateFormatter.pmSymbol = symbols.pmSymbol
        #else
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        #endif
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
        applyDisplayLocale()
        dateFormatter.dateFormat = getHoverDateFormat(timeChart: timeChart, dontShowTime: inFearGreedView)
        for index in indices {
            let date = Date(timeIntervalSince1970: (lowestTimeStamp[safely: index] ?? 0.0) / 1000)
            localTimes.append(dateFormatter.string(from: date))
        }
        
        // Third pass: format temporary times (one dateFormat set)
        let timeSuffix = Date.uses24HourClock ? "HH:mm" : "hh:mm a"
        dateFormatter.dateFormat = "dd MMM '\(localizedAt)' \(timeSuffix)"
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
            return dontShowTime ? "MMM dd, YYYY" : "MMM dd '\(localizedAt)' \(timeSuffix)"
        case .aMonth, .threeMonths, .aYear:
            return "MMM dd, YYYY"
        case .max:
            return "MMM YYYY"
        default:
            return "MMM dd '\(localizedAt)' \(timeSuffix)"
        }
    }
    
    func getTimeOnHover(index: Int, dates: [Double], timeChart: TimeCharts?, dontShowTime: Bool = false) -> String {
        let date = Date(timeIntervalSince1970: (dates[safely: index] ?? 0.0) / 1000)
        applyDisplayLocale()
        dateFormatter.dateFormat = getHoverDateFormat(timeChart: timeChart, dontShowTime: dontShowTime)
        return dateFormatter.string(from: date)
    }
    
    func getTemporaryTimeOnHover(index: Int, dates: [Double]) -> String {
        let date = Date(timeIntervalSince1970: (dates[safely: index] ?? 0.0) / 1000)
        applyDisplayLocale()
        dateFormatter.dateFormat = "dd MMM '\(localizedAt)' \(Date.uses24HourClock ? "HH:mm" : "hh:mm a")"
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
        applyDisplayLocale()
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
            return "MMM dd '\(localizedAt)' \(timeSuffix)"
        case .aMonth, .aYear:
            return "MMM dd, YYYY"
        case .max:
            return "MMM YYYY"
        default:
            return "dd MMM '\(localizedAt)' \(timeSuffix)"
        }
    }
    
    func getTimeOnHoverExchange(readerSize: CGSize, offset: CGPoint, prices: [Double], dates: [Double], timeChart: TimeCharts?) -> String {
        let position = chartLinearSeriesIndex(x: offset.x, width: readerSize.width, pointCount: prices.count)
        
        let date = Date(timeIntervalSince1970: (dates[safely: position] ?? 0.0) / 1000)
        applyDisplayLocale()
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
        applyDisplayLocale()
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

enum ChartHoverValueStyle {
    case currency(threshold: FormattingThreshold, currency: CurrencyModel? = nil)
    case integer
    case decimal(fractionLength: Int)
}

@Observable @MainActor
final class ChartHoverState {
    var helper = ChartHoverController()
    var hoverPriceWidthSize: CGFloat = 0
    var hoverTimeWidthSize: CGFloat = 0
    var hoverCandleTimeWidthSize: CGFloat = 0
    var chartSize: CGSize = .zero
    var isDragging = false
    var valueStyle: ChartHoverValueStyle
    var hidesValues = false

    private var timer: Timer?

    init(valueStyle: ChartHoverValueStyle = .currency(threshold: .million)) {
        self.valueStyle = valueStyle
    }

    var hoverTime: String {
        helper.hoverTimes.first ?? "0"
    }

    var hoverPrice: String {
        if hidesValues {
            return String.stars
        }

        return formattedValue(helper.hoverPrices.first ?? 0)
    }

    var differenceValue: String {
        if hidesValues {
            return String.stars
        }

        let first = helper.hoverPrices[safely: 0] ?? 0
        let second = helper.hoverPrices[safely: 1] ?? 0
        let percent = Double.getDifferenceInPercent(between: second, and: first)?.safeValue ?? 0
        let sign = percent.roundTo(places: 2) < 0 ? "" : "+"
        return "\(sign)\(formattedDelta(second - first))"
    }

    var differencePercent: String {
        let first = helper.hoverPrices[safely: 0] ?? 0
        let second = helper.hoverPrices[safely: 1] ?? 0
        let difference = Double.getDifferenceInPercent(between: second, and: first) ?? 0
        let sign = difference >= 0 ? "+" : "-"
        return "\(sign)\(difference.safeValue.removeZerosFromEnd(force: true).withoutSymbol)%"
    }

    var rangeChangeColor: Color {
        let difference = (helper.hoverPrices[safely: 1] ?? 0) - (helper.hoverPrices[safely: 0] ?? 0)
        return difference.roundTo(places: 7).changeColor
    }

    func graphColor(idle: Color) -> Color {
        guard helper.hoverPrices.count == 2, isDragging else {
            return idle
        }

        let first = helper.hoverPrices[safely: 0] ?? 0
        let second = helper.hoverPrices[safely: 1] ?? 0
        let change = (second - first).roundTo(places: 7)

        if change == 0 {
            let percent = Double.getDifferenceInPercent(between: second, and: first)?.roundTo(places: 7)
            return percent?.changeColor ?? .onSurfaceDim
        }

        return change.changeColor
    }

    func timeLabelX(pointX: CGFloat) -> CGFloat {
        getPriceXPosition(
            position: pointX,
            textSize: hoverTimeWidthSize,
            readerWidthSize: chartSize.width
        ) - hoverTimeWidthSize / 2
    }

    func priceLabelX(pointX: CGFloat) -> CGFloat {
        getPriceXPosition(
            position: pointX,
            textSize: hoverPriceWidthSize,
            readerWidthSize: chartSize.width
        ) - hoverTimeWidthSize / 2
    }

    func timeLabelX(prices: [Double], dropCount: Int = 0) -> CGFloat {
        let index = dropCount > 0
            ? currentPaddedIndex(priceCount: prices.count, dropCount: dropCount)
            : currentLinearIndex(priceCount: prices.count)
        let pointX = prices.point(at: index, rect: chartSize, dropCount: dropCount).x
        return timeLabelX(pointX: pointX)
    }

    func priceLabelX(prices: [Double], dropCount: Int = 0) -> CGFloat {
        let index = dropCount > 0
            ? currentPaddedIndex(priceCount: prices.count, dropCount: dropCount)
            : currentLinearIndex(priceCount: prices.count)
        let pointX = prices.point(at: index, rect: chartSize, dropCount: dropCount).x
        return priceLabelX(pointX: pointX)
    }

    func currentLinearIndex(priceCount: Int) -> Int {
        guard chartSize.width > 0 else { return 0 }

        let hoverPoints = helper.offset.map(\.x)
        let hoverPoint: CGFloat = helper.hoverPrices.count == 2
            ? hoverPoints.reduce(0, +) / 2
            : hoverPoints.first ?? 0

        return chartLinearSeriesIndex(x: hoverPoint, width: chartSize.width, pointCount: priceCount)
    }

    func currentPaddedIndex(priceCount: Int, dropCount: Int) -> Int {
        guard chartSize.width > 0 else { return 0 }

        let hoverPoint = helper.hoverPrices.count == 2
            ? helper.offset.map(\.x).reduce(0, +) / 2
            : helper.offset.first?.x ?? 0

        return Int(CGFloat(priceCount - dropCount) / (chartSize.width / hoverPoint))
    }

    func linearDragIndices(priceCount: Int, timestamps: [Double]) -> [Int] {
        let firstTimestamp = timestamps.normalized.first ?? 0
        let timestampCount = Double(timestamps.count)

        return helper.offset.map { offsetPoint in
            let offsetRatio = offsetPoint.x / chartSize.width
            guard offsetRatio >= firstTimestamp else { return -1 }

            let indexOffset = timestampCount * firstTimestamp
            let maxIndex = max(0, priceCount)
            let spatialIndex = Double(maxIndex) * Double(offsetPoint.x / chartSize.width)
            let index = spatialIndex - indexOffset

            if index.isNaN || index.isInfinite {
                return -1
            }

            return Int(index)
        }
    }

    func linearDragPositions(
        priceCount: Int,
        timestamps: [Double],
        pointAt: (Int, CGSize) -> CGPoint
    ) -> [CGPoint] {
        linearDragIndices(priceCount: priceCount, timestamps: timestamps).map {
            pointAt($0, chartSize)
        }
    }

    func paddedDragPositions(prices: [Double], dropCount: Int) -> [CGPoint] {
        let dragPositions = helper.offset.map {
            (CGFloat(prices.count - dropCount) / (chartSize.width / $0.x)).safeValue
        }.map {
            prices.point(at: Int($0), rect: chartSize, dropCount: dropCount)
        }.map {
            CGPoint(x: $0.x - 0.5, y: $0.y)
        }

        return isDragging ? dragPositions : [dragPositions.first ?? .zero]
    }

    @discardableResult
    func applyTouches(
        _ touches: [CGPoint],
        canUpdate: Bool,
        hasSeries: Bool,
        limitToFirstTouch: Bool = false
    ) -> Bool {
        guard canUpdate else { return false }
        guard hasSeries, !touches.isEmpty else {
            endDrag()
            return false
        }

        scheduleDragStartIfNeeded(hasTouches: true)

        let source = limitToFirstTouch ? [touches.first ?? .zero] : touches
        helper.offset = source.map {
            CGPoint(x: max(0, min($0.x, chartSize.width.rounded(.down) - 0.00001)), y: $0.y)
        }
        return true
    }

    func updateLinear(
        touches: [CGPoint],
        prices: [Double],
        dates: [Double],
        timeChart: TimeCharts?,
        canUpdate: Bool = true,
        inFearGreedView: Bool = false,
        compareDates: [Double]? = nil,
        comparePrices: [Double]? = nil,
        limitToFirstTouch: Bool = false
    ) {
        guard applyTouches(
            touches,
            canUpdate: canUpdate,
            hasSeries: !dates.isEmpty,
            limitToFirstTouch: limitToFirstTouch
        ) else {
            return
        }

        helper.getHoverPrice(
            readerSize: chartSize,
            offset: helper.offset,
            prices: prices,
            dates: dates,
            timeChart: timeChart,
            compareDates: compareDates,
            comparePrices: comparePrices,
            inFearGreedView: inFearGreedView,
            isDragging: isDragging
        )
    }

    func endDrag() {
        isDragging = false
        timer?.invalidate()
        timer = nil
    }

    private func scheduleDragStartIfNeeded(hasTouches: Bool) {
        guard !isDragging else { return }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isDragging = hasTouches

                if self.isDragging {
#if IS_APP
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
                }
            }
        }
    }

    private func formattedValue(_ value: Double) -> String {
        switch valueStyle {
        case .currency(let threshold, let currency):
            if let currency {
                return value.formatCurrency(threshold: threshold, currency: currency)
            }
            return value.formatCurrency(threshold: threshold)
        case .integer:
            return "\(Int(value))"
        case .decimal(let fractionLength):
            return "\(value.formatted(.number.precision(.fractionLength(fractionLength))))"
        }
    }

    private func formattedDelta(_ value: Double) -> String {
        switch valueStyle {
        case .currency(let threshold, let currency):
            if let currency {
                return value.formatCurrency(threshold: threshold, currency: currency)
            }
            return value.formatCurrency(threshold: threshold)
        case .integer:
            return "\(Int(value))"
        case .decimal(let fractionLength):
            return value.formatted(.number.precision(.fractionLength(fractionLength)))
        }
    }
}

@MainActor
protocol ChartHoverHosting: AnyObject {
    var hover: ChartHoverState { get }
}

extension ChartHoverHosting {
    var hoverHelper: ChartHoverController {
        get { hover.helper }
        set { hover.helper = newValue }
    }

    var hoverPriceWidthSize: CGFloat {
        get { hover.hoverPriceWidthSize }
        set { hover.hoverPriceWidthSize = newValue }
    }

    var hoverTimeWidthSize: CGFloat {
        get { hover.hoverTimeWidthSize }
        set { hover.hoverTimeWidthSize = newValue }
    }

    var hoverCandleTimeWidthSize: CGFloat {
        get { hover.hoverCandleTimeWidthSize }
        set { hover.hoverCandleTimeWidthSize = newValue }
    }

    var chartSize: CGSize {
        get { hover.chartSize }
        set { hover.chartSize = newValue }
    }

    var isDragging: Bool {
        get { hover.isDragging }
        set { hover.isDragging = newValue }
    }

    var differenceValue: String { hover.differenceValue }
    var differencePercent: String { hover.differencePercent }
    var hoverTime: String { hover.hoverTime }
    var hoverPrice: String { hover.hoverPrice }
}
