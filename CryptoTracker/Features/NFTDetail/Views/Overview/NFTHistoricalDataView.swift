//
//  HistoricalDataView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 5/13/25.
//

import SwiftUI

struct NFTHistoricalDataView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    let nftDetailModel: NFTDetail?
    
    @ScaledMetric private var scale: CGFloat = 1
    
    private let selectedCurrency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            
            VStack(spacing: 16) {
                changeView
                
                Separator()
            
                allTimeHighView
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
                    change: nftDetailModel?.floor_price_in_usd_24h_percentage_change
                )
                
                if !isHorizontal {
                    Separator()
                }
                
                HistoricDataChangeView(
                    timeframe: "7 Day",
                    change: nftDetailModel?.floor_price_7d_percentage_change?.usd
                )
                
                if !isHorizontal {
                    Separator()
                }
                
                HistoricDataChangeView(
                    timeframe: "14 Day",
                    change: nftDetailModel?.floor_price_14d_percentage_change?.usd
                )
            }
            
            Separator()
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading) {
                HistoricDataChangeView(
                    timeframe: "30 Day",
                    change: nftDetailModel?.floor_price_30d_percentage_change?.usd
                )
                
                if !isHorizontal {
                    Separator()
                }
                
                HistoricDataChangeView(
                    timeframe: "60 Day",
                    change: nftDetailModel?.floor_price_60d_percentage_change?.usd
                )
                
                if !isHorizontal {
                    Separator()
                }
                
                HistoricDataChangeView(
                    timeframe: "1 Year",
                    change: nftDetailModel?.floor_price_1y_percentage_change?.usd
                )
            }
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
                    .accessibilityLabel("Change since all time high: ")
                
                PriceChangePercentView(
                    change: nftDetailModel?.ath_change_percentage?.usd,
                    accessibleTimeframe: "",
                    isDownloading: nftDetailModel == nil
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
                    text: nftDetailModel?.ath_date?.usd?.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ)?.daysAgo ?? "00000000",
                    isDownloading: nftDetailModel?.ath_date == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
}
