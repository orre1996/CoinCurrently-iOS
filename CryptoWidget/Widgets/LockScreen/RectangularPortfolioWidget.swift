//
//  RectangularPortfolioWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2023-09-13.
//

import SwiftUI
import WidgetKit

struct RectangularPortfolioWidget: View {
    @Environment(\.colorScheme) var scheme
    
    var entry: PortfolioEntry?
    
    private var portfolioCoins: [Pie] {
        entry?.portfolioCoins ?? []
    }
    
    var body: some View {
        if let url = URL(string: "portfolio") {
            ZStack {
                AccessoryWidgetBackground()
                    .cornerRadius(8)
                
                VStack(spacing: 2) {
                    ShimmeringText(
                        text: entry?.totalValue?.formatCurrency(threshold: FormattingThreshold.million) ?? "000000",
                        isDownloading: entry == nil
                    )
                    .font(.satoshiBold(18))
                    .foregroundStyle(Color.onSurface(for: scheme))
                    .privacySensitive()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    
                    portfolioChangeView
                }
                .padding(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .widgetURL(url)
        }
    }
    
    @ViewBuilder
    private var portfolioChangeView: some View {
        let changePercent = entry?.portfolioDailyChangePercent
        let showDash = (changePercent?.isInfinite ?? true) || portfolioCoins.isEmpty
        let safeChange = changePercent?.isInfinite ?? false ? 0 : changePercent
        let decimals = safeChange?.changePercentDecimalPoints ?? 2
        let roundedChange = safeChange?.roundTo(places: decimals) ?? 0
        let formattedChange = roundedChange.formatted(
            .number.precision(.fractionLength(decimals))
        ).changeWithSymbol
        
        HStack(spacing: 4) {
            PriceChangeValueView(
                change: entry?.portfolioDailyChangeValue,
                size: .extraSmall,
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
            .font(.satoshiBold(12))
            .opacity(0.75)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}
