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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            
            VStack(spacing: 16) {
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
            .cardBackground()
        }
    }
    
    private var headerView: some View {
        Text("Historical Data")
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiBold(22))
            .accessibilityAddTraits(.isHeader)
    }
    
    @ViewBuilder
    private var changeView: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        VStack(spacing: 16) {
            AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading) {
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
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading) {
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
    }
    
    @ViewBuilder
    private var allTimeRangeView: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        let progress = (cryptoDetailModel?.market_data?.current_price?.getConvertedCurrency() ?? 1) / (cryptoDetailModel?.market_data?.ath?.getConvertedCurrency() ?? 0)
        
        let atlDate = cryptoDetailModel?.market_data?.atl_date?.getConvertedCurrency()?.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)
        let formattedAtlDate = atlDate?.formatted(date: .abbreviated, time: .omitted)
        
        let athDate = cryptoDetailModel?.market_data?.ath_date?.getConvertedCurrency()?.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)
        let formattedAthDate = athDate?.formatted(date: .abbreviated, time: .omitted)

        VStack(alignment: .leading, spacing: 0) {
            Text("All-Time Range")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceContainerDim)
            
            CustomProgressBarView(
                progress: progress,
                foregroundColor: .primary
            )
            .padding(.vertical, 12)
            .accessibilityHidden(true)
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 0 : 16, horizontalAlignment: .leading) {
                let atlPrice = cryptoDetailModel?.market_data?.atl?.getConvertedCurrency()?.formatCurrency(threshold: FormattingThreshold.none)
                
                VStack(alignment: .leading, spacing: 4) {
                    ShimmeringText(
                        text: atlPrice ?? "0000",
                        isDownloading: cryptoDetailModel?.market_data?.atl == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                    .accessibilityLabel("From \(atlPrice ?? "")")
                    
                    
                    ShimmeringText(
                        text: formattedAtlDate ?? "0000000",
                        isDownloading: formattedAtlDate == nil
                    )
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .font(.satoshiBold(12))
                    .accessibilityLabel("on \(formattedAtlDate?.description ?? "")")
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
                    .font(.satoshiBold(16))
                    .accessibilityLabel("to \(athPrice ?? "")")
                    
                    ShimmeringText(
                        text: formattedAthDate ?? "0000000",
                        isDownloading: formattedAthDate == nil
                    )
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .font(.satoshiBold(12))
                    .accessibilityLabel("on \(formattedAthDate?.description ?? "")")
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var allTimeLowView: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("All-Time Low %")
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                    .accessibilityHidden(true)
                
                PriceChangePercentView(
                    change: cryptoDetailModel?.market_data?.atl_change_percentage?.getConvertedCurrency(),
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
                Text("Since All-Time Low")
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                    .accessibilityLabel("Days since all time low: ")
                
                ShimmeringText(
                    text: cryptoDetailModel?.market_data?.atl_date?.getConvertedCurrency()?.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)?.daysAgo ?? "00000000",
                    isDownloading: cryptoDetailModel?.market_data?.atl_date == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
    
    @ViewBuilder
    private var allTimeHighView: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact
        
        AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("All-Time High %")
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                    .accessibilityHidden(true)
                
                PriceChangePercentView(
                    change: cryptoDetailModel?.market_data?.ath_change_percentage?.getConvertedCurrency(),
                    accessibleTimeframe: "Change since all time high: ",
                    isDownloading: cryptoDetailModel?.market_data?.ath_change_percentage == nil
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
                Text("Since All-Time High")
                    .foregroundStyle(Color.onSurfaceContainerDim)
                    .font(.satoshiBold(12))
                    .accessibilityLabel("Days since all time high: ")
                
                ShimmeringText(
                    text: cryptoDetailModel?.market_data?.ath_date?.getConvertedCurrency()?.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)?.daysAgo ?? "00000000",
                    isDownloading: cryptoDetailModel?.market_data?.ath_date == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
    
    @ViewBuilder
    private var genesisDateView: some View {
        let genesisDate = cryptoDetailModel?.genesis_date?.convertStringToDate(dateFormat: .yyyyMMdd, gmtTimeZone: false)
        let formattedGenesisDate = genesisDate?.formatted(date: .abbreviated, time: .omitted)
        
        VStack(alignment: .leading, spacing: 4) {
            Text("Genesis Date")
                .foregroundStyle(Color.onSurfaceContainerDim)
                .font(.satoshiBold(12))
            
            ShimmeringText(
                text: formattedGenesisDate ?? "Unknown",
                isDownloading: cryptoDetailModel?.market_data?.market_cap == nil
            )
            .foregroundStyle(Color.onSurface)
            .font(.satoshiBold(16))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
