//
//  NewPriceChangeView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 3/31/25.
//

import SwiftUI

struct PriceChangePercentView: View {
#if IS_WIDGET
    @Environment(\.colorScheme) var scheme
#endif

    let change: Double?
    var size: ChangeSize = .medium
    var accessibleTimeframe = String.timeframeAccessible
    var spacing: CGFloat = 4
    let isDownloading: Bool
    
    var body: some View {
        let safeChange = change?.isInfinite ?? false ? 0 : change
        let roundedChange = safeChange?.roundTo(places: safeChange?.changePercentDecimalPoints ?? 2) ?? 0
        let formattedChange = safeChange?.formattedChangePercent() ?? "0.00%"
        let accessibleChange = safeChange?.changePercentAccessible ?? ""
        
        HStack(spacing: spacing) {
            PriceChangeDirectionView(
                change: roundedChange,
                size: size,
                isDownloading: isDownloading
            )
            
            ShimmeringText(
                text: formattedChange,
                isDownloading: isDownloading
            )
            .lineLimit(1)
            .font(.satoshiBold(size.fontSize))
            .foregroundStyle(changeTextColor(for: roundedChange))
            .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText(
            direction: change?.directionAccessible ?? "",
            accessibleChange: accessibleChange
        ))
    }
    
    private func changeTextColor(for roundedChange: Double) -> Color {
#if IS_WIDGET
        roundedChange.changeColor(for: scheme)
#else
        roundedChange.changeColor
#endif
    }
    
    private func accessibilityLabelText(direction: String, accessibleChange: String) -> String {
        if accessibleTimeframe.isEmpty {
            return "Price change: \(direction) \(accessibleChange) percent"
        }
        return "\(accessibleTimeframe) price change: \(direction) \(accessibleChange) percent"
    }
}
