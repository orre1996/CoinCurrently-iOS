//
//  CompareHistoricDataView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 8/23/25.
//

import SwiftUI

struct CompareHistoricDataView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let mainCryptoInfo: CurrencyDataModel?
    let compareCryptoInfo: CurrencyDataModel?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            
            VStack(spacing: 16) {
                mainAllTimeRangeView
                
                Separator()
                
                compareAllTimeRangeView
                
                Separator()
                
                sinceAthView
                
                Separator()
                
                sinceAtlView
                
                Separator()
                
                genesisDateView
            }
            .cardBackground()
        }
        .padding(.horizontal, 16)
    }
    
    private var headerView: some View {
        Text(Localization.string("Historical Data"))
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiBold(22))
            .accessibilityAddTraits(.isHeader)
    }
    
    @ViewBuilder
    private var mainAllTimeRangeView: some View {
        allTimeRangeView(
            cryptoInfo: mainCryptoInfo,
            progressColor: .primary50,
            isDownloading: mainCryptoInfo?.symbol == nil
        )
    }
    
    @ViewBuilder
    private var compareAllTimeRangeView: some View {
        allTimeRangeView(
            cryptoInfo: compareCryptoInfo,
            progressColor: .blue50,
            isDownloading: compareCryptoInfo?.symbol == nil
        )
    }
    
    @ViewBuilder
    private func allTimeRangeView(
        cryptoInfo: CurrencyDataModel?,
        progressColor: Color,
        isDownloading: Bool
    ) -> some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        let progress = (cryptoInfo?.market_data?.current_price?.getConvertedCurrency() ?? 1) / (cryptoInfo?.market_data?.ath?.getConvertedCurrency() ?? 0)
        
        let atlDate = cryptoInfo?.market_data?.atl_date?.getConvertedCurrency()?.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)
        let formattedAtlDate = atlDate?.localizedAbbreviatedDate
        let atlPrice = cryptoInfo?.market_data?.atl?.getConvertedCurrency()
        
        let athDate = cryptoInfo?.market_data?.ath_date?.getConvertedCurrency()?.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)
        let formattedAthDate = athDate?.localizedAbbreviatedDate
        let athPrice = cryptoInfo?.market_data?.ath?.getConvertedCurrency()
        
        let atlPriceFormatted = atlPrice?.formatCurrency(threshold: FormattingThreshold.none) ?? "0000"
        let athPriceFormatted = athPrice?.formatCurrency(threshold: FormattingThreshold.none) ?? "000000000"
        
        VStack(alignment: .leading, spacing: 0) {
            ShimmeringText(
                text: Localization.format("All-Time Range (%@)", cryptoInfo?.symbol?.uppercased() ?? "0000"),
                isDownloading: isDownloading
            )
            .font(.satoshiBold(12))
            .foregroundStyle(Color.onSurfaceContainerDim)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Localization.format("%@ All-Time Range", cryptoInfo?.name ?? ""))
            
            CustomProgressBarView(
                progress: progress,
                foregroundColor: progressColor
            )
            .padding(.vertical, 12)
            .accessibilityHidden(true)
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 0 : 16, horizontalAlignment: .leading) {
                VStack(alignment: .leading, spacing: 4) {
                    ShimmeringText(
                        text: atlPriceFormatted,
                        isDownloading: cryptoInfo?.market_data?.atl == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                    .accessibilityHidden(true)
                    
                    ShimmeringText(
                        text: formattedAtlDate ?? "0000000",
                        isDownloading: formattedAtlDate == nil
                    )
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .font(.satoshiBold(12))
                    .accessibilityHidden(true)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibleRangeEndpointLabel(prefix: "From", price: atlPrice, date: formattedAtlDate))
                
                if isHorizontal {
                    Spacer(minLength: 16)
                        .accessibilityHidden(true)
                }
                
                VStack(alignment: isHorizontal ? .trailing : .leading, spacing: 4) {
                    ShimmeringText(
                        text: athPriceFormatted,
                        isDownloading: cryptoInfo?.market_data?.ath == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                    .accessibilityHidden(true)
                    
                    ShimmeringText(
                        text: formattedAthDate ?? "0000000",
                        isDownloading: formattedAthDate == nil
                    )
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .font(.satoshiBold(12))
                    .accessibilityHidden(true)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibleRangeEndpointLabel(prefix: "to", price: athPrice, date: formattedAthDate))
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var sinceAthView: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        let mainDaysAgo = mainCryptoInfo?.market_data?.ath_date?.getConvertedCurrency()?.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)?.daysAgo
        let compareDaysAgo = compareCryptoInfo?.market_data?.ath_date?.getConvertedCurrency()?.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)?.daysAgo
        
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.string("Since All-Time High"))
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceContainerDim)
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8) {
                HStack(spacing: 8) {
                    CompareRectangleView(
                        color: .primary50
                    )
                    .accessibilityHidden(true)
                    
                    ShimmeringText(
                        text: mainDaysAgo ?? Localization.string("Unknown"),
                        isDownloading: mainCryptoInfo?.market_data?.ath_date == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibleDaysAgoLabel(name: mainCryptoInfo?.name, daysAgo: mainDaysAgo))
                
                HStack(spacing: 8) {
                    CompareRectangleView(
                        color: .blue50
                    )
                    .accessibilityHidden(true)
                    
                    ShimmeringText(
                        text: compareDaysAgo ?? Localization.string("Unknown"),
                        isDownloading: compareCryptoInfo?.market_data?.ath_date == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibleDaysAgoLabel(name: compareCryptoInfo?.name, daysAgo: compareDaysAgo))
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var sinceAtlView: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        let mainDaysAgo = mainCryptoInfo?.market_data?.atl_date?.getConvertedCurrency()?.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)?.daysAgo
        let compareDaysAgo = compareCryptoInfo?.market_data?.atl_date?.getConvertedCurrency()?.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)?.daysAgo
        
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.string("Since All-Time Low"))
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceContainerDim)
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8) {
                HStack(spacing: 8) {
                    CompareRectangleView(
                        color: .primary50
                    )
                    .accessibilityHidden(true)
                    
                    ShimmeringText(
                        text: mainDaysAgo ?? "00000000",
                        isDownloading: mainCryptoInfo?.market_data?.atl_date == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibleDaysAgoLabel(name: mainCryptoInfo?.name, daysAgo: mainDaysAgo))
                
                HStack(spacing: 8) {
                    CompareRectangleView(
                        color: .blue50
                    )
                    .accessibilityHidden(true)
                    
                    ShimmeringText(
                        text: compareDaysAgo ?? "00000000",
                        isDownloading: compareCryptoInfo?.market_data?.atl_date == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibleDaysAgoLabel(name: compareCryptoInfo?.name, daysAgo: compareDaysAgo))
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var genesisDateView: some View {
        let mainGenesisDate = mainCryptoInfo?.genesis_date?.convertStringToDate(dateFormat: .yyyyMMdd, gmtTimeZone: false)
        let mainFormattedGenesisDate = mainGenesisDate?.localizedAbbreviatedDate
        let compareGenesisDate = compareCryptoInfo?.genesis_date?.convertStringToDate(dateFormat: .yyyyMMdd, gmtTimeZone: false)
        let compareFormattedGenesisDate = compareGenesisDate?.localizedAbbreviatedDate
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.string("Genesis Date"))
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceContainerDim)
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8) {
                HStack(spacing: 8) {
                    CompareRectangleView(
                        color: .primary50
                    )
                    .accessibilityHidden(true)
                    
                    ShimmeringText(
                        text: mainFormattedGenesisDate ?? Localization.string("Unknown"),
                        isDownloading: mainCryptoInfo?.market_data?.atl_date == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibleGenesisDateLabel(name: mainCryptoInfo?.name, date: mainFormattedGenesisDate))
                
                HStack(spacing: 8) {
                    CompareRectangleView(
                        color: .blue50
                    )
                    .accessibilityHidden(true)
                    
                    ShimmeringText(
                        text: compareFormattedGenesisDate ?? Localization.string("Unknown"),
                        isDownloading: compareCryptoInfo?.market_data?.atl_date == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibleGenesisDateLabel(name: compareCryptoInfo?.name, date: compareFormattedGenesisDate))
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    private func accessibleRangeEndpointLabel(prefix: String, price: Double?, date: String?) -> String {
        let priceText = price?.formatAccessibleCurrency() ?? ""
        let dateText = date ?? Localization.string("Unknown date")
        let key = prefix == "to" ? "to %1$@ on %2$@" : "From %1$@ on %2$@"
        return Localization.format(key, priceText, dateText)
    }
    
    private func accessibleDaysAgoLabel(name: String?, daysAgo: String?) -> String {
        Localization.format("%1$@: %2$@", name ?? "", daysAgo ?? Localization.string("Unknown"))
    }
    
    private func accessibleGenesisDateLabel(name: String?, date: String?) -> String {
        Localization.format("%1$@: %2$@", name ?? "", date ?? Localization.string("Unknown"))
    }
}
