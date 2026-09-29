//
//  CryptoDetailStatisticsView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 5/15/25.
//

import SwiftUI

struct CryptoDetailStatisticsView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let cryptoDetailModel: CurrencyDataModel?
    let timeChart: TimeCharts
    let prices: [Double]?
    let totalMarketCap: Double?

    private var isHorizontal: Bool {
        #if IS_WATCH
        false
        #else
        !category.isAccessibilityCategory || verticalSizeClass == .compact
        #endif
    }

    private var isRangeHorizontal: Bool {
        #if IS_WATCH
        true
        #else
        isHorizontal
        #endif
    }

    private var valueFont: Font {
        #if IS_WATCH
        .satoshiBold(14)
        #else
        .satoshiBold(16)
        #endif
    }
    
    private var horizontalPadding: CGFloat {
        #if IS_WATCH
        8
        #else
        16
        #endif
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            
            VStack(spacing: 8) {
                rangeView
                
                Separator()
                
                marketCapView
                
                Separator()
                
                domainceView
                
                Separator()
                
                if cryptoDetailModel?.market_data?.market_cap == nil || cryptoDetailModel?.market_data?.max_supply != nil {
                    supplyView
                } else {
                    supplyViewNoMax
                }
            }
            .cardBackground(padding: 8)
        }
    }
    
    private var headerView: some View {
        Text(AppCopy.string("Statistics"))
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiBold(22))
            .accessibilityAddTraits(.isHeader)
    }
    
    @ViewBuilder
    private var rangeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppCopy.string(timeChart.rangeTitle))
                .foregroundStyle(Color.onSurfaceContainerDim)
                .font(.satoshiBold(12))
            
            rangeProgressBar
                .accessibilityHidden(true)
            
            AdaptiveStack(isHorizontal: isRangeHorizontal, spacing: isRangeHorizontal ? horizontalPadding : 8, horizontalAlignment: .leading) {
                let low = prices?.min()?.formatCurrency(threshold: FormattingThreshold.none)
                
                ShimmeringText(
                    text: low ?? "00000000000",
                    isDownloading: prices?.min() == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(valueFont)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(AppCopy.format("From %@", low ?? ""))
                
                let high = prices?.max()?.formatCurrency(threshold: FormattingThreshold.none)
                
                ShimmeringText(
                    text: high ?? "00000000000",
                    isDownloading: prices?.max() == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(valueFont)
                .frame(maxWidth: .infinity, alignment: isRangeHorizontal ? .trailing : .leading)
                .accessibilityLabel(AppCopy.format("to %@", high ?? ""))
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
        let marketCap = cryptoDetailModel?.market_data?.market_cap?.getConvertedCurrency()
        
        AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? horizontalPadding : 8, horizontalAlignment: .leading, verticalAlignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppCopy.string("Market Cap Rank"))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                
                ShimmeringText(
                    text: cryptoDetailModel?.market_cap_rank == nil ? "-" : "#\(cryptoDetailModel?.market_cap_rank ?? 0)",
                    isDownloading: cryptoDetailModel == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(valueFont)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                cryptoDetailModel?.market_cap_rank == nil
                    ? AppCopy.format("%@, %@", AppCopy.string("Market Cap Rank"), AppCopy.string("No rank"))
                    : AppCopy.format("%@, %@", AppCopy.string("Market Cap Rank"), "\(cryptoDetailModel?.market_cap_rank ?? 0)")
            )
            
            if !isHorizontal {
                Separator()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(AppCopy.string("Market Cap"))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                
                ShimmeringText(
                    text: marketCap?.formatCurrency(threshold: FormattingThreshold.none, maxDecimals: (marketCap ?? 0) >= 1_000_000_000 ? 0 : nil) ?? "00000000000",
                    isDownloading: cryptoDetailModel?.market_data?.market_cap == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(valueFont)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(shortCurrencyAccessibilityLabel(title: "Market Cap", value: marketCap))
        }
    }
    
    @ViewBuilder
    private var domainceView: some View {
        let volume = cryptoDetailModel?.market_data?.total_volume?.getConvertedCurrency()
        
        AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? horizontalPadding : 8, horizontalAlignment: .leading, verticalAlignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppCopy.string("Market Dominance"))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                
                let marketCap = cryptoDetailModel?.market_data?.market_cap?.getConvertedCurrency()
                
                if let marketCap, let totalMarketCap, totalMarketCap > 0 {
                    compressedPriceText(
                        value: (marketCap / totalMarketCap) * 100,
                        font: .satoshiBold(12)
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(valueFont)
                } else {
                    ShimmeringText(
                        text: "0.00%",
                        isDownloading: marketCap == nil || totalMarketCap == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(valueFont)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            
            if !isHorizontal {
                Separator()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(AppCopy.string("24 Hour Volume"))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                
                ShimmeringText(
                    text: volume?.formatCurrency(threshold: FormattingThreshold.none, maxDecimals: (volume ?? 0) >= 1_000_000_000 ? 0 : nil) ?? "00000000000",
                    isDownloading: cryptoDetailModel?.market_data?.total_volume == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(valueFont)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(shortCurrencyAccessibilityLabel(title: "24 Hour Volume", value: volume))
        }
    }
    
    private func shortCurrencyAccessibilityLabel(title: String, value: Double?) -> String {
        let formattedValue = value?.formatAccessibleCurrency() ?? ""
        return AppCopy.format("%@, %@", AppCopy.string(title), formattedValue)
    }
    
    private func compressedPriceText(
        value: Double,
        font: Font
    ) -> Text {

        let isNegative = value < 0
        let absValue = abs(value)

        guard absValue > 0 else {
            return Text("0%")
        }

        // Locale-aware formatter (ONLY for separator + fallback formatting)
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal

        let decimalSeparator = formatter.decimalSeparator ?? "."

        // High precision invariant formatting
        let invariant = String(format: "%.4f", absValue)

        guard let dotIndex = invariant.firstIndex(of: ".") else {
            return Text("\(formatter.string(from: NSNumber(value: absValue)) ?? "\(absValue)")%")
        }

        let decimals = invariant[invariant.index(after: dotIndex)...]
        let zeroCount = decimals.prefix { $0 == "0" }.count
        let significant = decimals.dropFirst(zeroCount).prefix(4)

        // Normal values → regular localized formatting
        if zeroCount < 2 {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits =
                absValue < 0.02 ? 7 :
                absValue < 1 ? 4 : 2

            let formatted = formatter.string(from: NSNumber(value: absValue)) ?? "\(absValue)"
            return Text("\(formatted)%")
        }

        // Tiny values → compressed format
        return Text(isNegative ? "-" : "")
            + Text("0\(decimalSeparator)")
            + Text("0")
            + Text("\(zeroCount)")
                .font(font)
                .baselineOffset(-4)
            + Text("\(significant)%")
    }
    
    @ViewBuilder
    private var supplyView: some View {
        let circulatingSupply = cryptoDetailModel?.market_data?.circulating_supply
        let maxSupply = cryptoDetailModel?.market_data?.max_supply

        VStack(alignment: .leading, spacing: 0) {
            Text(AppCopy.string("Supply Circulation"))
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceContainerDim)
            
            CustomProgressBarView(
                progress: cryptoDetailModel?.market_data?.max_supply == nil ? 0 : (circulatingSupply ?? 1) / (maxSupply ?? 1),
                foregroundColor: .primary
            )
            .padding(.vertical, 12)
            .accessibilityHidden(true)
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 0 : 8, horizontalAlignment: .leading) {
                let supply = circulatingSupply?.formatCurrency(
                    threshold: FormattingThreshold.billion,
                    currency: CurrencyModel.empty,
                    maxDecimals: 0
                ) ?? "000000000"
                
                VStack(alignment: .leading, spacing: 4) {
                    ShimmeringText(
                        text: supply,
                        isDownloading: cryptoDetailModel?.market_data?.atl == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(valueFont)
                    
                    Text(AppCopy.string("Circulating Supply"))
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .font(.satoshiBold(12))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(AppCopy.format("Circulating Supply: %@", supply))
                
                if isHorizontal {
                    Spacer(minLength: 16)
                }
                
                let maxSupplyValue = cryptoDetailModel?.market_data?.max_supply
                let maxSupplyText = maxSupplyValue?.formatCurrency(
                    threshold: FormattingThreshold.billion,
                    currency: CurrencyModel.empty,
                    maxDecimals: 0) ?? "∞"
                let maxSupplyAccessibility = maxSupplyValue == nil
                    ? AppCopy.string("Max supply: unlimited")
                    : AppCopy.format("Max supply: %@", maxSupplyText)
                
                VStack(alignment: isHorizontal ? .trailing : .leading, spacing: 4) {
                    ShimmeringText(
                        text: maxSupplyText,
                        isDownloading: cryptoDetailModel?.market_data?.ath == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(valueFont)
                    
                    ShimmeringText(
                        text: AppCopy.string("Max Supply"),
                        isDownloading: cryptoDetailModel?.market_data == nil
                    )
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .font(.satoshiBold(12))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(maxSupplyAccessibility)
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    
    @ViewBuilder
    private var supplyViewNoMax: some View {
        AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? horizontalPadding : 8, horizontalAlignment: .leading, verticalAlignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppCopy.string("Circulating Supply"))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                
                ShimmeringText(
                    text: cryptoDetailModel?.market_data?.circulating_supply?.formatCurrency(
                        threshold: FormattingThreshold.billion,
                        currency: CurrencyModel.empty,
                        maxDecimals: 0
                    ) ?? "000000000",
                    isDownloading: cryptoDetailModel?.market_data?.atl == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(valueFont)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            
            if !isHorizontal {
                Separator()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(AppCopy.string("Max Supply"))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                
                Text("∞")
                    .foregroundStyle(Color.onSurface)
                    .font(valueFont)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(AppCopy.string("Max supply: unlimited"))
        }
    }
}
