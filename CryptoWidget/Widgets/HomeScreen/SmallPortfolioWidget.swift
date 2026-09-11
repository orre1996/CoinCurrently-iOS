//
//  SmallPortfolioWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2020-12-19.
//

import SwiftUI

struct SmallPortfolioWidget: View {
    @Environment(\.colorScheme) var scheme
    
    var entry: PortfolioEntry?
    
    private var portfolioCoins: [Pie] {
        entry?.portfolioCoins ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Portfolio Value")
                .foregroundStyle(Color.onSurfaceDimmer(for: scheme))
                .font(.satoshiBold(12))
            
            ShimmeringText(
                text: entry?.totalValue?.formatCurrency() ?? "000000",
                isDownloading: entry == nil
            )
            .foregroundStyle(Color.onSurface(for: scheme))
            .font(.satoshiBold(22))
            .privacySensitive()
            
            Spacer(minLength: 12)
            
            Text("24h Change")
                .foregroundStyle(Color.onSurfaceDimmer(for: scheme))
                .font(.satoshiBold(12))
            
            changeView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .widgetURL(URL(string: "portfolio"))
    }
    
    @ViewBuilder
    private var changeView: some View {
        let changePercent = entry?.portfolioDailyChangePercent
        let showDash = (changePercent?.isInfinite ?? true) || portfolioCoins.isEmpty
        let safeChange = changePercent?.isInfinite ?? false ? 0 : changePercent
        let decimals = safeChange?.changePercentDecimalPoints ?? 2
        let roundedChange = safeChange?.roundTo(places: decimals) ?? 0
        let formattedChange = roundedChange.formatted(
            .number.precision(.fractionLength(decimals))
        ).changeWithSymbol

        OverflowLayout(spacing: 4) {
            PriceChangeValueView(
                change: entry?.portfolioDailyChangeValue,
                size: .small,
                hideData: false,
                accessibleTimeframe: "24 hour",
                isDownloading: entry == nil
            )
            .privacySensitive()

            ShimmeringText(
                text: "(\(showDash ? "-" : (formattedChange + "%")))",
                isDownloading: entry == nil || changePercent == nil
            )
            .foregroundStyle(
                showDash
                    ? Color.onSurfaceDim(for: scheme)
                    : safeChange?.changeColor(for: scheme) ?? Color.onSurfaceDim(for: scheme)
            )
            .font(.satoshiBold(14))
            .opacity(0.75)
        }
    }
}
