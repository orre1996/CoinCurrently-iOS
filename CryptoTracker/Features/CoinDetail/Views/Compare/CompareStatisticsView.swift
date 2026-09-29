//
//  CompareStatisticsView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 8/23/25.
//

import SwiftUI

struct CompareStatisticsView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let mainCryptoInfo: CurrencyDataModel?
    let compareCryptoInfo: CurrencyDataModel?
    
    let mainPrices: [Double]?
    let comparePrices: [Double]?
    let selectedTimeframe: TimeCharts
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            
            VStack(spacing: 16) {
                priceView
                
                Separator()
                
                priceChangeView
                
                Separator()
                
                marketCapView
                
                Separator()
                
                volumeView
                
                Separator()
                
                supplyView
            }
            .cardBackground()
        }
        .padding(.horizontal, 16)
    }
    
    private var headerView: some View {
        Text(Localization.string("Statistics"))
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiBold(22))
            .accessibilityAddTraits(.isHeader)
    }
    
    @ViewBuilder
    private var priceView: some View {
        let mainPrice = mainCryptoInfo?.market_data?.current_price?.getConvertedCurrency()
        let comparePrice = compareCryptoInfo?.market_data?.current_price?.getConvertedCurrency()
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.string("Price"))
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
            
            let mainPriceFormatted = mainPrice?.formatCurrency(threshold: FormattingThreshold.none) ?? "000000000"
            let comparePriceFormatted = comparePrice?.formatCurrency(threshold: FormattingThreshold.none) ?? "000000000"
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8) {
                HStack(spacing: 8) {
                    CompareRectangleView(
                        color: .primary50
                    )
                    .accessibilityHidden(true)
                    
                    ShimmeringText(
                        text: mainPriceFormatted,
                        isDownloading: mainPrice == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(accessiblePriceLabel(name: mainCryptoInfo?.name, value: mainPrice))
                
                HStack(spacing: 8) {
                    CompareRectangleView(
                        color: .blue50
                    )
                    .accessibilityHidden(true)
                    
                    ShimmeringText(
                        text: comparePriceFormatted,
                        isDownloading: comparePrice == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(accessiblePriceLabel(name: compareCryptoInfo?.name, value: comparePrice))
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var priceChangeView: some View {
        let mainPriceChange = Double.getDifferenceInPercent(between: mainPrices?.last, and: mainPrices?.first)
        let comparePriceChange = Double.getDifferenceInPercent(between: comparePrices?.last, and: comparePrices?.first)
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.string("Price Change"))
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)

            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8) {
                HStack(spacing: 8) {
                    CompareRectangleView(
                        color: .primary50
                    )
                    .accessibilityHidden(true)
                    
                    PriceChangePercentView(
                        change: mainPriceChange,
                        accessibleTimeframe: selectedTimeframe.accessibilityTimeframe,
                        isDownloading: mainPriceChange == nil
                    )
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessiblePriceChangeLabel(name: mainCryptoInfo?.name, change: mainPriceChange))
                
                HStack(spacing: 8) {
                    CompareRectangleView(
                        color: .blue50
                    )
                    .accessibilityHidden(true)
                    
                    PriceChangePercentView(
                        change: comparePriceChange,
                        accessibleTimeframe: selectedTimeframe.accessibilityTimeframe,
                        isDownloading: comparePriceChange == nil
                    )
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessiblePriceChangeLabel(name: compareCryptoInfo?.name, change: comparePriceChange))
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var marketCapView: some View {
        let mainMarketCap = mainCryptoInfo?.market_data?.market_cap?.getConvertedCurrency()
        let mainRank = mainCryptoInfo?.market_cap_rank
        let compareMarketCap = compareCryptoInfo?.market_data?.market_cap?.getConvertedCurrency()
        let compareRank = compareCryptoInfo?.market_cap_rank
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.string("Market Cap"))
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
            
            CustomProgressBarView(
                progress: (mainMarketCap ?? 0) / (compareMarketCap ?? 0),
                foregroundColor: .primary50,
                backgroundColor: .clear,
                downloading: mainMarketCap == nil || compareMarketCap == nil
            )
            .padding(.top, 8)
            .accessibilityHidden(true)
            
            CustomProgressBarView(
                progress: (compareMarketCap ?? 0) / (mainMarketCap ?? 0),
                foregroundColor: .blue50,
                backgroundColor: .clear,
                downloading: mainMarketCap == nil || compareMarketCap == nil
            )
            .padding(.bottom, 8)
            .accessibilityHidden(true)
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8) {
                HStack(spacing: 8) {
                    CompareRectangleView(
                        color: .primary50
                    )
                    .accessibilityHidden(true)
                    
                    HStack(spacing: 4) {
                        ShimmeringText(
                            text: mainMarketCap?.formatCurrency() ?? "000000000",
                            isDownloading: mainMarketCap == nil
                        )
                        .foregroundStyle(Color.onSurface)
                        .font(.satoshiBold(16))
                        
                        ShimmeringText(
                            text: mainRank == nil ? "-" : "#\(mainRank ?? 0)",
                            isDownloading: mainMarketCap == nil
                        )
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .font(.satoshiBold(16))
                    }
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibleMarketCapLabel(name: mainCryptoInfo?.name, value: mainMarketCap, rank: mainRank))
                
                Spacer(minLength: 0)
                    .accessibilityHidden(true)
                
                HStack(spacing: 8) {
                    CompareRectangleView(
                        color: .blue50
                    )
                    .accessibilityHidden(true)
                    
                    HStack(spacing: 4) {
                        ShimmeringText(
                            text: compareMarketCap?.formatCurrency() ?? "000000000",
                            isDownloading: compareMarketCap == nil
                        )
                        .foregroundStyle(Color.onSurface)
                        .font(.satoshiBold(16))
                        
                        ShimmeringText(
                            text: compareRank == nil ? "-" : "#\(compareRank ?? 0)",
                            isDownloading: compareMarketCap == nil
                        )
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .font(.satoshiBold(16))
                    }
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibleMarketCapLabel(name: compareCryptoInfo?.name, value: compareMarketCap, rank: compareRank))
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var volumeView: some View {
        let mainVolume = mainCryptoInfo?.market_data?.total_volume?.getConvertedCurrency()
        let compareVolume = compareCryptoInfo?.market_data?.total_volume?.getConvertedCurrency()
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.string("24 Hour Volume"))
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
            
            CustomProgressBarView(
                progress: (mainVolume ?? 0) / (compareVolume ?? 0),
                foregroundColor: .primary50,
                backgroundColor: .clear,
                downloading: mainVolume == nil || compareVolume == nil
            )
            .padding(.top, 8)
            .accessibilityHidden(true)
            
            CustomProgressBarView(
                progress: (compareVolume ?? 0) / (mainVolume ?? 0),
                foregroundColor: .blue50,
                backgroundColor: .clear,
                downloading: mainVolume == nil || compareVolume == nil
            )
            .padding(.bottom, 8)
            .accessibilityHidden(true)
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8) {
                HStack(spacing: 8) {
                    CompareRectangleView(
                        color: .primary50
                    )
                    .accessibilityHidden(true)
                    
                    ShimmeringText(
                        text: mainVolume?.formatCurrency() ?? "000000000",
                        isDownloading: mainVolume == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibleVolumeLabel(name: mainCryptoInfo?.name, value: mainVolume))
                
                HStack(spacing: 8) {
                    CompareRectangleView(
                        color: .blue50
                    )
                    .accessibilityHidden(true)
                    
                    ShimmeringText(
                        text: compareVolume?.formatCurrency() ?? "000000000",
                        isDownloading: compareVolume == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibleVolumeLabel(name: compareCryptoInfo?.name, value: compareVolume))
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var supplyView: some View {
        let mainSupply = mainCryptoInfo?.market_data?.circulating_supply
        let compareSupply = compareCryptoInfo?.market_data?.circulating_supply
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.string("Circulating Supply"))
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
            
            CustomProgressBarView(
                progress: (mainSupply ?? 0) / (compareSupply ?? 0),
                foregroundColor: .primary50,
                backgroundColor: .clear,
                downloading: mainSupply == nil || compareSupply == nil
            )
            .padding(.top, 8)
            .accessibilityHidden(true)
            
            CustomProgressBarView(
                progress: (compareSupply ?? 0) / (mainSupply ?? 0),
                foregroundColor: .blue50,
                backgroundColor: .clear,
                downloading: mainSupply == nil || compareSupply == nil
            )
            .padding(.bottom, 8)
            .accessibilityHidden(true)
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8) {
                HStack(spacing: 8) {
                    CompareRectangleView(
                        color: .primary50
                    )
                    .accessibilityHidden(true)
                    
                    ShimmeringText(
                        text: mainSupply?.formatCurrency(currency: CurrencyModel.empty) ?? "000000000",
                        isDownloading: mainSupply == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(accessibleSupplyLabel(name: mainCryptoInfo?.name, value: mainSupply))
                
                HStack(spacing: 8) {
                    CompareRectangleView(
                        color: .blue50
                    )
                    .accessibilityHidden(true)
                    
                    ShimmeringText(
                        text: compareSupply?.formatCurrency(currency: CurrencyModel.empty) ?? "000000000",
                        isDownloading: compareSupply == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(accessibleSupplyLabel(name: compareCryptoInfo?.name, value: compareSupply))
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    private func accessiblePriceLabel(name: String?, value: Double?) -> String {
        "\(name ?? ""): \(value?.formatCurrency(threshold: FormattingThreshold.none, accessible: true) ?? "")"
    }
    
    private func accessibleVolumeLabel(name: String?, value: Double?) -> String {
        "\(name ?? ""): \(value?.formatAccessibleCurrency() ?? "")"
    }
    
    private func accessibleMarketCapLabel(name: String?, value: Double?, rank: Int?) -> String {
        let marketCap = value?.formatCurrency(accessible: true) ?? ""
        let rankLabel = rank.map { Localization.format("rank %d", $0) } ?? Localization.string("No rank")
        return Localization.format("%1$@: %2$@, %3$@", name ?? "", marketCap, rankLabel)
    }
    
    private func accessiblePriceChangeLabel(name: String?, change: Double?) -> String {
        let timeframe = Localization.string(selectedTimeframe.accessibilityTimeframe)
        guard let change else {
            return Localization.format(
                "%1$@: %2$@ price change: %3$@",
                name ?? "",
                timeframe,
                Localization.string("Not available")
            )
        }
        
        let safeChange = change.isInfinite ? 0 : change
        let decimals = safeChange.changePercentDecimalPoints
        let accessibleChange = safeChange.numberAccessible(maxPlaces: decimals)
        return Localization.format(
            "%1$@: %2$@ price change: %3$@ %4$@ percent",
            name ?? "",
            timeframe,
            Localization.string(change.directionAccessible),
            accessibleChange
        )
    }
    
    private func accessibleSupplyLabel(name: String?, value: Double?) -> String {
        "\(name ?? ""): \(value?.formatCurrency(currency: CurrencyModel.empty, accessible: true) ?? "")"
    }
}
