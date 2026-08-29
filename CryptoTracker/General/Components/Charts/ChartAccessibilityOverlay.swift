//
//  ChartAccessibilityOverlay.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-05-22.
//

import SwiftUI
import UIKit

struct ChartAccessibilityOverlay: View {
    let timeStamps: [Double]
    let prices: [Double]
    let timeChart: TimeCharts
    var comparePrices: [Double]? = nil
    var mainSeriesName: String? = nil
    var compareSeriesName: String? = nil
    var dontShowTime: Bool = false
    var useExchangeDateFormat: Bool = false
    var currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    var priceFormatter: ((Double) -> String)? = nil
    var showPercentChangeFromStart: Bool = false
    var trailingPadding: CGFloat = 0
    
    private var sectionCount: Int {
        min(9, timeStamps.count)
    }
    
    var body: some View {
        if sectionCount > 0 {
            HStack(spacing: 0) {
                ForEach(1...sectionCount, id: \.self) { sectionIndex in
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(accessibilityLabel(for: sectionIndex))
                        .accessibilitySortPriority(Double(sectionCount - sectionIndex))
                }
            }
            .padding(.trailing, trailingPadding)
            .allowsHitTesting(false)
        }
    }
    
    private func accessibilityLabel(for sectionIndex: Int) -> String {
        let dataIndex = chartAxisTimestampIndex(
            labelIndex: sectionIndex,
            labelCount: sectionCount,
            dataCount: timeStamps.count
        )
        
        let date = formattedDate(at: dataIndex)
        let priceText = formattedPrice(at: dataIndex, from: prices)
        
        if let comparePrices {
            let comparePriceText = formattedPrice(at: dataIndex, from: comparePrices)
            let mainLabel = labeledPrice(name: mainSeriesName, price: priceText)
            let compareLabel = labeledPrice(name: compareSeriesName, price: comparePriceText)
            return "\(date), \(mainLabel), \(compareLabel)"
        }
        
        return "\(date), \(priceText)"
    }
    
    private func labeledPrice(name: String?, price: String) -> String {
        guard let name, !name.isEmpty else { return price }
        return "\(name): \(price)"
    }
    
    private func formattedDate(at dataIndex: Int) -> String {
        let date = Date(timeIntervalSince1970: (timeStamps[safely: dataIndex] ?? 0.0) / 1000)
        return date.accessibleChartHoverDate(
            timeChart: timeChart,
            dontShowTime: dontShowTime,
            useExchangeFormat: useExchangeDateFormat
        )
    }
    
    private func formattedPrice(at dataIndex: Int, from prices: [Double]) -> String {
        guard let price = prices[safely: dataIndex], price != -1 else {
            return "N/A"
        }
        
        var priceText = formatAccessiblePrice(price)
        
        if showPercentChangeFromStart,
           let firstPrice = prices.first(where: { $0 != -1 }),
           let change = Double.getDifferenceInPercent(between: price, and: firstPrice) {
            priceText += ", \(accessiblePercentChange(change))"
        }
        
        return priceText
    }
    
    private func accessiblePercentChange(_ change: Double) -> String {
        let safeChange = change.isInfinite ? 0 : change
        let decimals = safeChange.changePercentDecimalPoints
        let accessibleChange = abs(safeChange).numberAccessible(maxPlaces: decimals)
        let direction = safeChange.directionAccessible.lowercased()
        return "\(direction) \(accessibleChange) percent"
    }
    
    private func formatAccessiblePrice(_ price: Double) -> String {
        if let priceFormatter {
            return priceFormatter(price)
        }
        
        return price.formatAccessibleCurrency(currency: currency)
    }
}

private struct ChartAccessibilityOverlayModifier: ViewModifier {
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    @State private var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    
    let timeStamps: [Double]
    let prices: [Double]
    let timeChart: TimeCharts
    let comparePrices: [Double]?
    let mainSeriesName: String?
    let compareSeriesName: String?
    let dontShowTime: Bool
    let useExchangeDateFormat: Bool
    let currency: CurrencyModel
    let priceFormatter: ((Double) -> String)?
    let showPercentChangeFromStart: Bool
    let trailingPadding: CGFloat
    let chartTitle: String
    let chartSummary: String?
    let yAxisTitle: String
    
    private var isVoiceOverActive: Bool {
        accessibilityVoiceOverEnabled || isVoiceOverRunning
    }
    
    private var audioGraphDescriptor: ChartAudioGraphDescriptor {
        ChartAudioGraphDescriptor(
            title: chartTitle,
            summary: chartSummary,
            timeStamps: timeStamps,
            prices: prices,
            comparePrices: comparePrices,
            mainSeriesName: mainSeriesName,
            compareSeriesName: compareSeriesName,
            timeChart: timeChart,
            dontShowTime: dontShowTime,
            useExchangeDateFormat: useExchangeDateFormat,
            yAxisTitle: yAxisTitle,
            valueDescriptionProvider: { value in
                if let priceFormatter {
                    return priceFormatter(value)
                }
                return value.formatAccessibleCurrency(currency: currency)
            }
        )
    }
    
    func body(content: Content) -> some View {
        if isVoiceOverActive {
            ZStack {
                content
                    .accessibilityHidden(true)
                
                ChartAccessibilityOverlay(
                    timeStamps: timeStamps,
                    prices: prices,
                    timeChart: timeChart,
                    comparePrices: comparePrices,
                    mainSeriesName: mainSeriesName,
                    compareSeriesName: compareSeriesName,
                    dontShowTime: dontShowTime,
                    useExchangeDateFormat: useExchangeDateFormat,
                    currency: currency,
                    priceFormatter: priceFormatter,
                    showPercentChangeFromStart: showPercentChangeFromStart,
                    trailingPadding: trailingPadding
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilitySortPriority(-1)
            .modifier(ChartAudioGraphModifier(descriptor: audioGraphDescriptor))
            .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)) { _ in
                isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
            }
        } else {
            content
        }
    }
}

private struct ChartAudioGraphModifier: ViewModifier {
    let descriptor: ChartAudioGraphDescriptor
    
    func body(content: Content) -> some View {
        if descriptor.hasData {
            content.accessibilityChartDescriptor(descriptor)
        } else {
            content
        }
    }
}

extension View {
    func chartAccessibilityOverlay(
        timeStamps: [Double],
        prices: [Double],
        timeChart: TimeCharts,
        comparePrices: [Double]? = nil,
        mainSeriesName: String? = nil,
        compareSeriesName: String? = nil,
        dontShowTime: Bool = false,
        useExchangeDateFormat: Bool = false,
        currency: CurrencyModel? = nil,
        priceFormatter: ((Double) -> String)? = nil,
        showPercentChangeFromStart: Bool = false,
        trailingPadding: CGFloat = 0,
        chartTitle: String = "Chart",
        chartSummary: String? = nil,
        yAxisTitle: String = "Price"
    ) -> some View {
        modifier(
            ChartAccessibilityOverlayModifier(
                timeStamps: timeStamps,
                prices: prices,
                timeChart: timeChart,
                comparePrices: comparePrices,
                mainSeriesName: mainSeriesName,
                compareSeriesName: compareSeriesName,
                dontShowTime: dontShowTime,
                useExchangeDateFormat: useExchangeDateFormat,
                currency: currency ?? SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel(),
                priceFormatter: priceFormatter,
                showPercentChangeFromStart: showPercentChangeFromStart,
                trailingPadding: trailingPadding,
                chartTitle: chartTitle,
                chartSummary: chartSummary,
                yAxisTitle: yAxisTitle
            )
        )
    }
}
