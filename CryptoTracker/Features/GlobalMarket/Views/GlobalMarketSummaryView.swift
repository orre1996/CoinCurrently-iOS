//
//  GlobalMarketSummaryView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/20/26.
//

import SwiftUI

struct GlobalMarketSummaryView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    let marketCap: Double?
    let changePercent: Double?
    let selectedTimeframe: TimeCharts

    var body: some View {
        let isHorizontal = category.isAccessibilityCategory && verticalSizeClass == .regular

        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.string("Market Cap"))
                .font(.satoshiBold(18))
                .foregroundStyle(Color.onSurfaceDim)
            
            ShimmeringText(
                text: marketCap?.formatCurrency(
                    threshold: isHorizontal ? FormattingThreshold.million : FormattingThreshold.none,
                    maxDecimals: (marketCap ?? 0) >= 1_000_000_000 ? 0 : 2
                ) ?? "00000",
                isDownloading: marketCap == nil
            )
            .font(.satoshiBold(36))
            .foregroundStyle(Color.onSurface)
            
            changeView
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(categorySummaryAccessibilityLabel(isHorizontal: isHorizontal))
    }
    
    @ViewBuilder
    private var changeView: some View {
        let isHorizontal = category.isAccessibilityCategory && verticalSizeClass == .regular
        
        let roundedChange = changePercent ?? 0
        let formattedChange = roundedChange.formatted(
             isHorizontal
                ? .number.notation(.compactName).precision(.fractionLength(2))
                : .number.precision(.fractionLength(2))
        ).changeWithSymbol
        
        let changeValue = roundedChange.getChangeInValue(currentValue: marketCap ?? 0)
        
        OverflowLayout(spacing: 4) {
            PriceChangeValueView(
                change: changeValue,
                size: .extraSmall,
                accessibleTimeframe: selectedTimeframe.accessibilityTimeframe,
                isDownloading: marketCap == nil
            )
            
            ShimmeringText(
                text: "(\(formattedChange)%)",
                isDownloading: changePercent == nil
            )
            .foregroundStyle(roundedChange.changeColor)
            .font(.satoshiBold(12))
            
            Text(Localization.string(selectedTimeframe.timeAgoText))
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
        }
    }

    private func categorySummaryAccessibilityLabel(isHorizontal: Bool) -> String {
        let marketCap = marketCap ?? 0
        let formattingThreshold: FormattingThreshold = isHorizontal ? .million : .none
        let marketCapText = marketCap.formatCurrency(threshold: formattingThreshold, accessible: true)
        let roundedChange = changePercent ?? 0
        let formattedChangePercent = roundedChange.numberAccessible(maxPlaces: 2)
        let changeDirection = Localization.string(roundedChange >= 0 ? "Up" : "Down")
        
        return Localization.format(
            "Market Cap, market cap: %@. %@ market cap change: %@ %@ percent",
            marketCapText,
            Localization.string(selectedTimeframe.accessibilityTimeframe),
            changeDirection,
            formattedChangePercent
        )
    }
}
