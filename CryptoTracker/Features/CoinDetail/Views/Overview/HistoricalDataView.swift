//
//  HistoricalDataView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 5/13/25.
//

import SwiftUI

struct HistoricalDataView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    let cryptoDetailModel: CurrencyDataModel?
    
    @ScaledMetric private var scale: CGFloat = 1
    
    private let selectedCurrency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()

    private var isHorizontal: Bool {
        #if IS_WATCH
        false
        #else
        !category.isAccessibilityCategory || verticalSizeClass == .compact
        #endif
    }

    private var valueFont: Font {
        #if IS_WATCH
        .satoshiBold(14)
        #else
        .satoshiBold(16)
        #endif
    }

    private var valueChangeSize: ChangeSize {
        #if IS_WATCH
        .small
        #else
        .medium
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
            
            VStack(spacing: horizontalPadding) {
                changeView
                
                Separator()
                
                allTimeRangeView
                
                Separator()
                
                allTimeLowView
                
                Separator()
                
                allTimeHighView
                
                Separator()
                
                genesisDateView
            }
            .cardBackground(padding: horizontalPadding)
        }
    }
    
    private var headerView: some View {
        Text(AppCopy.string("Historical Data"))
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiBold(22))
            .accessibilityAddTraits(.isHeader)
    }
    
    @ViewBuilder
    private var changeView: some View {
        #if IS_WATCH
        VStack(spacing: 8) {
            changePair(
                leftTimeframe: "24 Hour",
                leftChange: cryptoDetailModel?.market_data?.price_change_percentage_24h,
                rightTimeframe: "7 Day",
                rightChange: cryptoDetailModel?.market_data?.price_change_percentage_7d
            )
            
            Separator()
            
            changePair(
                leftTimeframe: "14 Day",
                leftChange: cryptoDetailModel?.market_data?.price_change_percentage_14d,
                rightTimeframe: "30 Day",
                rightChange: cryptoDetailModel?.market_data?.price_change_percentage_30d
            )
            
            Separator()
            
            changePair(
                leftTimeframe: "60 Day",
                leftChange: cryptoDetailModel?.market_data?.price_change_percentage_60d,
                rightTimeframe: "1 Year",
                rightChange: cryptoDetailModel?.market_data?.price_change_percentage_1y
            )
        }
        #else
        VStack(spacing: 8) {
            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8, horizontalAlignment: .leading) {
                HistoricDataChangeView(
                    timeframe: "24 Hour",
                    change: cryptoDetailModel?.market_data?.price_change_percentage_24h
                )
                
                if !isHorizontal {
                    Separator()
                }
                
                HistoricDataChangeView(
                    timeframe: "7 Day",
                    change: cryptoDetailModel?.market_data?.price_change_percentage_7d
                )
                
                if !isHorizontal {
                    Separator()
                }
                
                HistoricDataChangeView(
                    timeframe: "14 Day",
                    change: cryptoDetailModel?.market_data?.price_change_percentage_14d
                )
            }
            
            Separator()
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8, horizontalAlignment: .leading) {
                HistoricDataChangeView(
                    timeframe: "30 Day",
                    change: cryptoDetailModel?.market_data?.price_change_percentage_30d
                )
                
                if !isHorizontal {
                    Separator()
                }
                
                HistoricDataChangeView(
                    timeframe: "60 Day",
                    change: cryptoDetailModel?.market_data?.price_change_percentage_60d
                )
                
                if !isHorizontal {
                    Separator()
                }
                
                HistoricDataChangeView(
                    timeframe: "1 Year",
                    change: cryptoDetailModel?.market_data?.price_change_percentage_1y
                )
            }
        }
        #endif
    }

    #if IS_WATCH
    private func changePair(
        leftTimeframe: String,
        leftChange: Double?,
        rightTimeframe: String,
        rightChange: Double?
    ) -> some View {
        HStack(spacing: 16) {
            HistoricDataChangeView(
                timeframe: leftTimeframe,
                change: leftChange
            )
            
            HistoricDataChangeView(
                timeframe: rightTimeframe,
                change: rightChange
            )
        }
    }
    #endif
    
    @ViewBuilder
    private var allTimeRangeView: some View {
        let progress = (cryptoDetailModel?.market_data?.current_price?.getConvertedCurrency() ?? 1) / (cryptoDetailModel?.market_data?.ath?.getConvertedCurrency() ?? 0)
        
        let atlDate = cryptoDetailModel?.market_data?.atl_date?.getConvertedCurrency()?.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)
        let formattedAtlDate = atlDate?.localizedAbbreviatedDate
        
        let athDate = cryptoDetailModel?.market_data?.ath_date?.getConvertedCurrency()?.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)
        let formattedAthDate = athDate?.localizedAbbreviatedDate

        VStack(alignment: .leading, spacing: 0) {
            Text(AppCopy.string("All-Time Range"))
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceContainerDim)
            
            CustomProgressBarView(
                progress: progress,
                foregroundColor: .primary
            )
            .padding(.vertical, 12)
            .accessibilityHidden(true)
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 0 : 8, horizontalAlignment: .leading) {
                let atlPrice = cryptoDetailModel?.market_data?.atl?.getConvertedCurrency()?.formatCurrency(threshold: FormattingThreshold.none)
                
                VStack(alignment: .leading, spacing: 4) {
                    ShimmeringText(
                        text: atlPrice ?? "0000",
                        isDownloading: cryptoDetailModel?.market_data?.atl == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(valueFont)
                    .accessibilityLabel(AppCopy.format("From %@", atlPrice ?? ""))
                    
                    
                    ShimmeringText(
                        text: formattedAtlDate ?? "0000000",
                        isDownloading: formattedAtlDate == nil
                    )
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .font(.satoshiBold(12))
                    .accessibilityLabel(AppCopy.format("on %@", formattedAtlDate ?? ""))
                }
                
                if isHorizontal {
                    Spacer(minLength: 16)
                }
                
                VStack(alignment: isHorizontal ? .trailing : .leading, spacing: 4) {
                    let athPrice = cryptoDetailModel?.market_data?.ath?.getConvertedCurrency()?.formatCurrency(threshold: FormattingThreshold.none)
                    
                    ShimmeringText(
                        text: cryptoDetailModel?.market_data?.ath?.getConvertedCurrency()?.formatCurrency(threshold: FormattingThreshold.none) ?? "000000000",
                        isDownloading: cryptoDetailModel?.market_data?.ath == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(valueFont)
                    .accessibilityLabel(AppCopy.format("to %@", athPrice ?? ""))
                    
                    ShimmeringText(
                        text: formattedAthDate ?? "0000000",
                        isDownloading: formattedAthDate == nil
                    )
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .font(.satoshiBold(12))
                    .accessibilityLabel(AppCopy.format("on %@", formattedAthDate ?? ""))
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var allTimeLowView: some View {
        AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8, horizontalAlignment: .leading, verticalAlignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppCopy.string("All-Time Low %"))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                    .accessibilityHidden(true)
                
                PriceChangePercentView(
                    change: cryptoDetailModel?.market_data?.atl_change_percentage?.getConvertedCurrency(),
                    size: valueChangeSize,
                    accessibleTimeframe: "Change since all time low: ",
                    isDownloading: cryptoDetailModel?.market_data?.atl_change_percentage == nil
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            
            if !isHorizontal {
                Separator()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(AppCopy.string("Since All-Time Low"))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                    .accessibilityLabel(AppCopy.string("Days since all time low: "))
                
                ShimmeringText(
                    text: cryptoDetailModel?.market_data?.atl_date?.getConvertedCurrency()?.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)?.daysAgo ?? "00000000",
                    isDownloading: cryptoDetailModel?.market_data?.atl_date == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(valueFont)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
    
    @ViewBuilder
    private var allTimeHighView: some View {
        AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8, horizontalAlignment: .leading, verticalAlignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppCopy.string("All-Time High %"))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                    .accessibilityHidden(true)
                
                PriceChangePercentView(
                    change: cryptoDetailModel?.market_data?.ath_change_percentage?.getConvertedCurrency(),
                    size: valueChangeSize,
                    accessibleTimeframe: "Change since all time high: ",
                    isDownloading: cryptoDetailModel?.market_data?.ath_change_percentage == nil
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
                Text(AppCopy.string("Since All-Time High"))
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                    .accessibilityLabel(AppCopy.string("Days since all time high: "))
                
                ShimmeringText(
                    text: cryptoDetailModel?.market_data?.ath_date?.getConvertedCurrency()?.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)?.daysAgo ?? "00000000",
                    isDownloading: cryptoDetailModel?.market_data?.ath_date == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(valueFont)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
    
    @ViewBuilder
    private var genesisDateView: some View {
        let genesisDate = cryptoDetailModel?.genesis_date?.convertStringToDate(dateFormat: .yyyyMMdd, gmtTimeZone: false)
        let formattedGenesisDate = genesisDate?.localizedAbbreviatedDate
        
        VStack(alignment: .leading, spacing: 4) {
            Text(AppCopy.string("Genesis Date"))
                .foregroundStyle(Color.onSurfaceContainerDim)
                .font(.satoshiBold(12))
            
            ShimmeringText(
                text: formattedGenesisDate ?? AppCopy.string("Unknown"),
                isDownloading: cryptoDetailModel?.market_data?.market_cap == nil
            )
            .foregroundStyle(Color.onSurface)
            .font(valueFont)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
