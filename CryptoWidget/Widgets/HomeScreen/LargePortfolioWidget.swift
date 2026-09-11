//
//  LargePortfolioWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2020-12-29.
//

import SwiftUI
import UIKit

struct LargePortfolioWidget: View {
    @Environment(\.colorScheme) var scheme
    
    var entry: PortfolioEntry?
    
    private var portfolioCoins: [Pie] {
        entry?.portfolioCoins ?? []
    }
    
    private var topCoins: [Pie] {
        entry?.topCoinsByProfitLoss ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            
            statsRow
                .padding(.top, 12)
            
            Separator()
                .padding(.vertical, 16)
            
            listHeader
            
            ForEach(topCoins, id: \.self) { pie in
                coinRow(for: pie)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .widgetURL(URL(string: "portfolio"))
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Portfolio Value")
                .foregroundStyle(Color.onSurfaceDimmer(for: scheme))
                .font(.satoshiBold(12))
            
            ShimmeringText(
                text: entry?.totalValue?.formatCurrency(threshold: FormattingThreshold.billion) ?? "000000",
                isDownloading: entry == nil
            )
            .foregroundStyle(Color.onSurface(for: scheme))
            .font(.satoshiBold(22))
            .privacySensitive()
        }
    }
    
    private var statsRow: some View {
        HStack(alignment: .top, spacing: 16) {
            statColumn(
                title: "24h Change",
                value: entry?.portfolioDailyChangeValue,
                percent: entry?.portfolioDailyChangePercent,
                accessibleTimeframe: "24 hour"
            )
            
            statColumn(
                title: "Profit/Loss",
                value: entry?.profitLossValue,
                percent: entry?.profitLossPercent,
                accessibleTimeframe: ""
            )
        }
    }
    
    private func statColumn(
        title: String,
        value: Double?,
        percent: Double?,
        accessibleTimeframe: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .foregroundStyle(Color.onSurfaceDimmer(for: scheme))
                .font(.satoshiBold(12))
            
            changeView(
                value: value,
                percent: percent,
                accessibleTimeframe: accessibleTimeframe
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var listHeader: some View {
        HStack(spacing: 0) {
            Text("Coin")
            
            Spacer(minLength: 16)
            
            Text("Profit/Loss")
        }
        .foregroundStyle(Color.onSurfaceDimmer(for: scheme))
        .font(.satoshiBold(12))
    }
    
    private func coinRow(for pie: Pie) -> some View {
        HStack(spacing: 8) {
            ShimmeringImageWithUIImage(
                image: coinImage(for: pie),
                downloading: entry == nil || pie.data?.image == nil,
                size: 16
            )
            
            ShimmeringText(
                text: pie.data?.symbol?.uppercased() ?? "0000",
                isDownloading: entry == nil
            )
            .foregroundStyle(Color.onSurface(for: scheme))
            .font(.satoshiBold(12))
            
            Spacer(minLength: 8)
            
            changeView(
                value: entry?.profitLossValue(for: pie),
                percent: entry?.profitLossPercent(for: pie),
                accessibleTimeframe: ""
            )
        }
        .padding(.top, 12)
    }
    
    @ViewBuilder
    private func changeView(
        value: Double?,
        percent: Double?,
        accessibleTimeframe: String
    ) -> some View {
        let showDash = (percent?.isInfinite ?? true) || portfolioCoins.isEmpty
        let safeChange = percent?.isInfinite ?? false ? 0 : percent
        let decimals = safeChange?.changePercentDecimalPoints ?? 2
        let roundedChange = safeChange?.roundTo(places: decimals) ?? 0
        let formattedChange = roundedChange.formatted(
            .number.precision(.fractionLength(decimals))
        ).changeWithSymbol
        
        OverflowLayout(spacing: 4) {
            PriceChangeValueView(
                change: value,
                size: .small,
                hideData: false,
                accessibleTimeframe: accessibleTimeframe,
                isDownloading: entry == nil
            )
            .privacySensitive()
            
            ShimmeringText(
                text: "(\(showDash ? "-" : (formattedChange + "%")))",
                isDownloading: entry == nil || percent == nil
            )
            .foregroundStyle(
                showDash
                    ? Color.onSurfaceDim(for: scheme)
                    : safeChange?.changeColor(for: scheme) ?? Color.onSurfaceDim(for: scheme)
            )
            .font(.satoshiBold(12))
            .opacity(0.75)
        }
    }
    
    private func coinImage(for pie: Pie?) -> UIImage {
        guard
            let imageURL = pie?.data?.image,
            let data = CoinImageCache.imageData(for: imageURL),
            let image = UIImage(data: data)
        else {
            return UIImage()
        }
        
        return image
    }
}
