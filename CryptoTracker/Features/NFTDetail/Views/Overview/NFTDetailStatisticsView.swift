//
//  CryptoDetailStatisticsView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 5/15/25.
//

import SwiftUI

struct NFTDetailStatisticsView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let nftDetailInfo: NFTDetail?
    let timeChart: TimeCharts
    let prices: [Double]?
    let chartCurrency: CurrencyModel
    let isFiatSelected: Bool
    let multiplier: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            
            VStack(spacing: 16) {
                rangeView
                
                Separator()
                
                marketCapView
                
                Separator()
                
                dailyStatsView
                
                Separator()
                
                supplyView
            }
            .cardBackground()
        }
    }
    
    private var headerView: some View {
        Text(Localization.string("Statistics"))
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiBold(22))
            .accessibilityAddTraits(.isHeader)
    }
    
    @ViewBuilder
    private var rangeView: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        VStack(alignment: .leading, spacing: 12) {
            Text(timeChart.rangeTitle)
                .foregroundStyle(Color.onSurfaceContainerDim)
                .font(.satoshiBold(12))
            
            rangeProgressBar
                .accessibilityHidden(true)
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading) {
                let low = prices?.min()?.formatCurrency(threshold: FormattingThreshold.none, currency: chartCurrency)
                let lowAccessible = accessibleRangePrice(prices?.min())
                
                ShimmeringText(
                    text: low ?? "00000000000",
                    isDownloading: prices?.isEmpty ?? true
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(Localization.format("From %@", lowAccessible))
                
                let high = prices?.max()?.formatCurrency(threshold: FormattingThreshold.none, currency: chartCurrency)
                let highAccessible = accessibleRangePrice(prices?.max())
                
                ShimmeringText(
                    text: high ?? "00000000000",
                    isDownloading: prices?.isEmpty ?? true
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
                .frame(maxWidth: .infinity, alignment: isHorizontal ?  .trailing : .leading)
                .accessibilityLabel(Localization.format("to %@", highAccessible))
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var rangeProgressBar: some View {
        let lowestPrice = prices?.min() ?? 0
        let highestPrice = prices?.max() ?? 0
        let currentPrice = prices?.last ?? 0
        let openPrice = prices?.first ?? 0
        let currentPriceNormalized = [openPrice, lowestPrice, highestPrice, currentPrice].normalized
        
        let rangeWidth = abs((currentPriceNormalized.first ?? 0) - (currentPriceNormalized.last ?? 0))
        let startPoint = min(currentPriceNormalized.first ?? 0, currentPriceNormalized.last ?? 0)
        let rangeColor = currentPrice >= openPrice ? Color.trendUp : Color.trendDown
        
        CustomProgressBarView(
            progress: rangeWidth,
            offset: startPoint,
            foregroundColor: rangeColor
        )
    }
    
    @ViewBuilder
    private var marketCapView: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        let marketCap = nftDetailInfo?.market_cap?.getSelectedPrice(isFiatSelected: isFiatSelected, multiplier: multiplier)
        
        AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.string("Market Cap Rank"))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                
                ShimmeringText(
                    text: nftDetailInfo?.market_cap_rank == nil ? "-" : "#\(nftDetailInfo?.market_cap_rank ?? 0)",
                    isDownloading: nftDetailInfo == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                nftDetailInfo?.market_cap_rank == nil
                    ? "Market Cap Rank, No rank"
                    : "Market Cap Rank, \(nftDetailInfo?.market_cap_rank ?? 0)"
            )
            
            if !isHorizontal {
                Separator()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.string("Market Cap"))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                
                ShimmeringText(
                    text: marketCap?.formatCurrency(threshold: FormattingThreshold.none, currency: chartCurrency) ?? "00000000000",
                    isDownloading: nftDetailInfo?.market_cap == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(shortCurrencyAccessibilityLabel(title: "Market Cap", value: marketCap, currency: chartCurrency))
        }
    }
    
    @ViewBuilder
    private var dailyStatsView: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        let volume = nftDetailInfo?.volume_24h?.getSelectedPrice(isFiatSelected: isFiatSelected, multiplier: multiplier)
        
        AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.string("24 Hour Sales"))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                
                let dailySales = nftDetailInfo?.one_day_sales
                
                ShimmeringText(
                    text: dailySales?.formatted(.number.precision(.fractionLength(0))) ?? "-",
                    isDownloading: nftDetailInfo == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            
            if !isHorizontal {
                Separator()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.string("24 Hour Volume"))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                
                ShimmeringText(
                    text: volume?.formatCurrency(threshold: FormattingThreshold.none, currency: chartCurrency) ?? "00000000000",
                    isDownloading: nftDetailInfo?.volume_24h == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(shortCurrencyAccessibilityLabel(title: "24 Hour Volume", value: volume, currency: chartCurrency))
        }
    }
    
    private func shortCurrencyAccessibilityLabel(title: String, value: Double?, currency: CurrencyModel) -> String {
        let formattedValue = value?.formatAccessibleCurrency(currency: currency) ?? ""
        return Localization.format("%@, %@", Localization.string(title), formattedValue)
    }
    
    private func accessibleRangePrice(_ value: Double?) -> String {
        value?.formatCurrency(
            threshold: FormattingThreshold.none,
            currency: accessibleRangeCurrency(),
            accessible: true
        ) ?? ""
    }
    
    private func accessibleRangeCurrency() -> CurrencyModel {
        guard !isFiatSelected else { return chartCurrency }
        
        if let symbol = nftDetailInfo?.native_currency_symbol?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !symbol.isEmpty {
            let spelledSymbol = symbol.uppercased().map { String($0) }.joined(separator: " ")
            return CurrencyModel(
                currency: spelledSymbol,
                code: symbol,
                symbol: symbol,
                locale: "",
                suffix: true
            )
        }
        
        return chartCurrency
    }

    @ViewBuilder
    private var supplyView: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        let totalSupply = nftDetailInfo?.total_supply
        
        AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.string("Unique Owners"))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                
                let uniqueOwners = nftDetailInfo?.number_of_unique_addresses
                let percent = Double.getDifferenceInPercent(between: Double((totalSupply ?? 0) - (uniqueOwners ?? 0)), and: Double(totalSupply ?? 0))
                
                let decimals = percent?.changePercentDecimalPoints ?? 2
                let roundedChange = percent?.roundTo(places: decimals)
                
                let formattedUniqueOwners = uniqueOwners?.formatted(.number.precision(.fractionLength(0))) ?? "Unknown"
                let formattedPercentOwners = abs(roundedChange ?? 0).formatted(.number.precision(.fractionLength(decimals)))
                
                ShimmeringText(
                    text: "\(formattedUniqueOwners) (\(formattedPercentOwners)%)",
                    isDownloading: nftDetailInfo?.number_of_unique_addresses == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            
            if !isHorizontal {
                Separator()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.string("Total Supply"))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                
                ShimmeringText(
                    text: totalSupply?.formatted(.number.precision(.fractionLength(0))) ?? "Unknown",
                    isDownloading: nftDetailInfo?.total_supply == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
}
