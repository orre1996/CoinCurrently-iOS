//
//  InlinePortfolioWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2023-09-09.
//

import SwiftUI

struct InlinePortfolioWidget: View {
    var entry: PortfolioEntry?
    
    var body: some View {
        if let url = URL(string: "portfolio") {
            let totalValue = entry?.totalValue?.formatCurrency(threshold: FormattingThreshold.million) ?? "000000"
            let safeChange = entry?.profitLossPercent?.isInfinite ?? false ? 0 : entry?.profitLossPercent
            let decimals = safeChange?.changePercentDecimalPoints ?? 2
            let roundedChange = safeChange?.roundTo(places: decimals) ?? 0
            let formattedPercent = abs(roundedChange).formatted(
                .number.precision(.fractionLength(decimals))
            ).changeWithSymbol
            
            Text(AppCopy.format("%1$@ P/L: %2$@%%", totalValue, formattedPercent))
                .privacySensitive()
                .widgetURL(url)
        }
    }
}

