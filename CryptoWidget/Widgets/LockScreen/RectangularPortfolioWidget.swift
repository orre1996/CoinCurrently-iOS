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
                
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("Value")
                        
                        Spacer(minLength: 8)
                        
                        NewShimmeringText(
                            text: entry?.totalValue?.formatCurrency() ?? "000000",
                            isDownloading: entry == nil
                        )
                        .privacySensitive()
                    }
                    .layoutPriority(1)
                    
                    Separator()
                    
                    HStack(spacing: 0) {
                        Text("24h")
                        
                        Spacer(minLength: 8)
                        
                        portfolioChangeView
                    }
                    .layoutPriority(1)
                    
                    Separator()
                    
                    coinChangeRow(
                        symbol: entry?.dailyWinnerPie?.data?.symbol?.uppercased(),
                        pie: entry?.dailyWinnerPie
                    )
                    .layoutPriority(1)
                    
                    Separator()
                    
                    coinChangeRow(
                        symbol: entry?.dailyLoserPie?.data?.symbol?.uppercased(),
                        pie: entry?.dailyLoserPie
                    )
                    .layoutPriority(1)
                }
                .padding(4)
            }
            .frame(maxHeight: .infinity)
            .minimumScaleFactor(0.7)
            .lineLimit(1)
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
        
        OverflowLayout(spacing: 4) {
            NewPriceChangeValueView(
                change: entry?.portfolioDailyChangeValue,
                size: .extraSmall,
                hideData: false,
                accessibleTimeframe: "24 hour",
                isDownloading: entry == nil
            )
            .privacySensitive()
            
            NewShimmeringText(
                text: "(\(showDash ? "-" : (formattedChange + "%")))",
                isDownloading: entry == nil || changePercent == nil
            )
            .foregroundStyle(
                showDash
                    ? Color.onSurfaceDim(for: scheme)
                    : safeChange?.changeColor(for: scheme) ?? Color.onSurfaceDim(for: scheme)
            )
            .font(.satoshiBold(12))
        }
    }
    
    @ViewBuilder
    private func coinChangeRow(symbol: String?, pie: Pie?) -> some View {
        HStack(spacing: 0) {
            NewShimmeringText(
                text: symbol ?? "0000",
                isDownloading: entry == nil
            )
            
            Spacer(minLength: 8)
            
            dailyChangeView(for: pie)
        }
        .frame(maxHeight: .infinity)
        .opacity(symbol == nil ? 0 : 1)
    }
    
    @ViewBuilder
    private func dailyChangeView(for pie: Pie?) -> some View {
        let changePercent = entry?.dailyChangePercent(for: pie)
        let showDash = (changePercent?.isInfinite ?? true) || pie == nil
        let safeChange = changePercent?.isInfinite ?? false ? 0 : changePercent
        let decimals = safeChange?.changePercentDecimalPoints ?? 2
        let roundedChange = safeChange?.roundTo(places: decimals) ?? 0
        let formattedChange = roundedChange.formatted(
            .number.precision(.fractionLength(decimals))
        ).changeWithSymbol
        
        OverflowLayout(spacing: 4) {
            NewPriceChangeValueView(
                change: entry?.dailyChangeValue(for: pie),
                size: .extraSmall,
                hideData: false,
                accessibleTimeframe: "24 hour",
                isDownloading: entry == nil
            )
            .privacySensitive()
            
            NewShimmeringText(
                text: "(\(showDash ? "-" : (formattedChange + "%")))",
                isDownloading: entry == nil || changePercent == nil
            )
            .foregroundStyle(
                showDash
                    ? Color.onSurfaceDim(for: scheme)
                    : safeChange?.changeColor(for: scheme) ?? Color.onSurfaceDim(for: scheme)
            )
            .font(.satoshiBold(12))
        }
    }
}
