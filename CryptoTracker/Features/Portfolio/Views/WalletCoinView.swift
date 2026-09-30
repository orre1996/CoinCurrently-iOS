//
//  WalletCoinView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/18/25.
//

import SwiftUI

struct WalletCoinView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1

    let toplist: Toplist?
    let token: TokenInfo?
    let hideData: Bool
    let isDownloading: Bool
    let index: Int
    let totalCount: Int
    let navigateToCoin: () -> Void
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    private var currentAmount: Double? {
        Double(token?.balance ?? "0")
    }
    
    private var currentPrice: Double? {
        toplist?.current_price
    }
    
    private var accessibilityLabelText: String {
        var components: [String] = []
        
        components.append(Localization.format("Asset %1$d of %2$d", index + 1, totalCount))
        
        let name = toplist?.name ?? token?.tokenSymbol ?? ""
        let amount = currentAmount ?? 0
        let holdingsValue = amount * (currentPrice ?? 0)
        
        if hideData {
            components.append(Localization.format("%1$@, holdings hidden", name))
        } else {
            let amountLabel = accessibleCoinAmountLabel(
                amount: amount,
                coinName: toplist?.name ?? toplist?.symbol ?? token?.tokenSymbol ?? ""
            )
            let holdingsText = holdingsValue.formatAccessibleCurrency()
            components.append(Localization.format("%1$@, holdings %2$@, %3$@", name, amountLabel, holdingsText))
        }
        
        components.append(priceChangeAccessibilityLabel)
        
        return components.joined(separator: ". ")
    }
    
    private func accessibleCoinAmountLabel(amount: Double, coinName: String) -> String {
        let amountText = amount.formatCurrency(currency: CurrencyModel.empty, accessible: true)
        let label = coinName.lowercased()
        
        guard !label.isEmpty else {
            return amountText
        }
        
        return "\(amountText) \(label)"
    }
    
    private var priceChangeAccessibilityLabel: String {
        let change = toplist?.price_change_percentage_7d_in_currency
        let safeChange = change?.isInfinite ?? false ? 0 : (change ?? 0)
        let decimals = safeChange.changePercentDecimalPoints
        let accessiblePercent = abs(safeChange).numberAccessible(maxPlaces: decimals)
        return Localization.format(
            "%@ price change: %@ %@ percent",
            Localization.string("7 days"),
            Localization.string(safeChange.directionAccessible),
            accessiblePercent
        )
    }
    
    private var formattedAmount: String {
        if isDownloading {
            return "00000"
        }
        
        if hideData {
            return String.stars
        }
        
        return currentAmount?.formatCurrency(currency: CurrencyModel.empty) ?? Localization.string("Missing Data")
    }
    
    private var formattedValue: String {
        if hideData {
            return String.stars
        }
        
        if currentPrice == nil {
            return Localization.string("Missing Data")
        }
        
        return ((currentAmount ?? 0) * (currentPrice ?? 0)).formatCurrency(threshold: FormattingThreshold.million)
    }
        
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            AdaptiveStack(
                isHorizontal: isHorizontal,
                spacing: 8,
                horizontalAlignment: .leading,
                verticalAlignment: .center
            ) {
                coinImageView
                
                coinInfoView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if isHorizontal {
                holdingsView
            }
            
            priceChangeView
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(accessibilityLabelText)
        .onTapGesture {
            navigateToCoin()
        }
    }
    
    @ViewBuilder
    private var coinImageView: some View {
        if isDownloading || toplist?.image != nil {
            ShimmeringImage(
                imageUrl: toplist?.image,
                downloading: isDownloading,
                size: 28 * min(scale, 1.5)
            )
            .accessibilityHidden(true)
        }
    }
    
    private var coinInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ShimmeringText(
                text: toplist?.symbol?.uppercased() ?? token?.tokenSymbol.uppercased() ?? "",
                isDownloading: isDownloading
            )
            .font(.satoshiBold(16))
            .foregroundStyle(Color.onSurface)
            
            ShimmeringText(
                text: toplist?.name ?? token?.tokenSymbol.uppercased() ?? "",
                isDownloading: isDownloading
            )
            .font(.satoshiBold(14))
            .foregroundStyle(Color.onSurfaceDimmer)
            
            if !isHorizontal {
                holdingsSubtitleView
            }
        }
    }
    
    @ViewBuilder
    private var holdingsView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ShimmeringText(
                text: formattedAmount,
                isDownloading: isDownloading
            )
            .font(.satoshiBold(16))
            .foregroundStyle(Color.onSurface)
            .multilineTextAlignment(.trailing)
            
            ShimmeringText(
                text: formattedValue,
                isDownloading: isDownloading
            )
            .font(.satoshiBold(14))
            .foregroundStyle(Color.onSurfaceDimmer)
            .multilineTextAlignment(.trailing)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.leading, 8)
    }
    
    @ViewBuilder
    private var holdingsSubtitleView: some View {
        ShimmeringText(
            text: formattedAmount,
            isDownloading: isDownloading
        )
        .foregroundStyle(Color.onSurfaceDimmer)
        .font(.satoshiBold(12))
        .multilineTextAlignment(.leading)
        
        ShimmeringText(
            text: formattedValue,
            isDownloading: isDownloading
        )
        .foregroundStyle(Color.onSurfaceDimmer)
        .font(.satoshiBold(12))
        .multilineTextAlignment(.leading)
    }
    
    @ViewBuilder
    private var priceChangeView: some View {
        MinimumTextSize(
            text: "999.9%",
            extraSize: 16 * min(scale, 1.5) + 4,
            alignment: .trailing
        ) {
            PriceChangePercentView(
                change: toplist?.price_change_percentage_7d_in_currency,
                accessibleTimeframe: "7 days",
                isDownloading: isDownloading
            )
        }
        .padding(.leading, 16)
        .accessibilityHidden(true)
    }
}
