//
//  NewPriceChangeView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 3/31/25.
//

import SwiftUI

struct PriceChangeValueView: View {
#if IS_WIDGET
    @Environment(\.colorScheme) var scheme
#endif

    let change: Double?
    var size: ChangeSize = .medium
    var hideData: Bool = false
    var accessibleTimeframe = String.timeframeAccessible
    var showDirection: Bool = true
    var formattingThreshold: FormattingThreshold = .thousand
    var selectedCurrency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    var useNumericContentTransition: Bool = false
    let isDownloading: Bool
    
    var body: some View {
        let decimals = change?.changeValueDecimalPoints ?? 2
        let roundedChange = change?.roundTo(places: decimals)
        let accessibleChange = change?.numberAccessible(maxPlaces: decimals) ?? ""
        
        HStack(spacing: 4) {
            if showDirection {
                PriceChangeDirectionView(
                    change: roundedChange,
                    size: size,
                    isDownloading: isDownloading
                )
            }
            
            let formattedChange = showDirection ? roundedChange?.formatCurrency(threshold: formattingThreshold, currency: selectedCurrency).changeWithoutSymbol ?? "N/A" : roundedChange?.formatCurrency(threshold: formattingThreshold).changeWithSymbol ?? "N/A"
            
            ShimmeringText(
                text: hideData ? String.stars : formattedChange,
                isDownloading: isDownloading,
                useNumericContentTransition: useNumericContentTransition
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

    private func changeTextColor(for roundedChange: Double?) -> Color {
#if IS_WIDGET
        roundedChange?.changeColor(for: scheme) ?? Color.onSurfaceDim(for: scheme)
#else
        roundedChange?.changeColor ?? .onSurfaceDim
#endif
    }
    
    private func accessibilityLabelText(direction: String, accessibleChange: String) -> String {
#if IS_APP
        let localizedDirection = direction.isEmpty ? "" : Localization.string(direction)
        if accessibleTimeframe.isEmpty {
            return Localization.format("Price change: %@ %@ percent", localizedDirection, accessibleChange)
        }
        return Localization.format(
            "%@ price change: %@ %@ percent",
            Localization.string(accessibleTimeframe),
            localizedDirection,
            accessibleChange
        )
#else
        if accessibleTimeframe.isEmpty {
            return "Price change: \(direction) \(accessibleChange) percent"
        }
        return "\(accessibleTimeframe) price change: \(direction) \(accessibleChange) percent"
#endif
    }
}
