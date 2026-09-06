//
//  PortfolioCoinView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/18/25.
//

import SwiftUI

struct PortfolioCoinView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1

    let pie: Pie?
    let transactions: [PortfolioTransaction]?
    let prices: [String: Double]
    let hideData: Bool
    let index: Int
    let totalCount: Int
    let navigateToCoin: () -> Void
    
    let selectedCurrency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    private var currentAmount: Double? {
        transactions?.getAmount()
    }
    
    private var currentPrice: Double {
        pie?.data?.holdingPrice(
            vsCurrencyPrices: prices,
            currencyCode: selectedCurrency.code
        ) ?? 0
    }
    
    private var accessibilityLabelText: String {
        var components: [String] = []
        
        components.append("Asset \(index + 1) of \(totalCount)")
        
        let name = pie?.data?.name ?? ""
        let amount = currentAmount ?? 0
        let holdingsValue = amount * currentPrice
        
        if hideData {
            components.append("\(name), holdings hidden")
        } else {
            let amountLabel = accessibleCoinAmountLabel(
                amount: amount,
                coinName: pie?.data?.name ?? pie?.data?.symbol ?? ""
            )
            let holdingsText = holdingsValue.formatAccessibleCurrency()
            components.append("\(name), holdings \(amountLabel), \(holdingsText)")
        }
        
        components.append(profitLossAccessibilityLabel)
        
        return components.joined(separator: ". ")
    }
    
    private var profitLossAccessibilityLabel: String {
        let profitValue = transactions?.getProfitValue(
            prices: prices,
            showCurrency: selectedCurrency.code
        )
        let profitPercent = transactions?.getProfitPercent(
            prices: prices,
            showCurrency: selectedCurrency.code
        )
        
        let safeChange = (profitPercent ?? 0).isInfinite ? 0 : (profitPercent ?? 0)
        let decimals = safeChange.changePercentDecimalPoints
        let accessiblePercent = abs(safeChange).numberAccessible(maxPlaces: decimals)
        let direction = safeChange.directionAccessible.lowercased()
        let percentText = "\(direction) \(accessiblePercent) percent"
        
        if hideData {
            return "Profit loss, \(percentText)"
        }
        
        let changeValue = profitValue ?? 0
        let valueDirection = changeValue.directionAccessible.lowercased()
        let valueText = abs(changeValue).formatAccessibleCurrency()
        return "Profit loss, \(valueDirection) \(valueText), \(percentText)"
    }
    
    private func accessibleCoinAmountLabel(amount: Double, coinName: String) -> String {
        let amountText = amount.formatCurrency(currency: CurrencyModel.empty, accessible: true)
        let label = coinName.lowercased()
        
        guard !label.isEmpty else {
            return amountText
        }
        
        return "\(amountText) \(label)"
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
            
            profitLossView
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(accessibilityLabelText)
        .onTapGesture {
            navigateToCoin()
        }
    }
    
    private var coinImageView: some View {
        ShimmeringImage(
            imageUrl: pie?.data?.image,
            downloading: pie?.data?.image == nil,
            size: 28 * min(scale, 1.5)
        )
        .accessibilityHidden(true)
    }
    
    private var coinInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ShimmeringText(
                text: pie?.data?.symbol?.uppercased() ?? "0000",
                isDownloading: pie?.data?.symbol == nil
            )
            .font(.satoshiBold(16))
            .foregroundStyle(Color.onSurface)
            
            ShimmeringText(
                text: pie?.data?.name ?? "0000000",
                isDownloading: pie?.data?.name == nil
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
                text: hideData ? String.stars : currentAmount?.formatCurrency(currency: CurrencyModel.empty) ?? "00000",
                isDownloading: pie?.data == nil
            )
            .font(.satoshiBold(16))
            .foregroundStyle(Color.onSurface)
            .multilineTextAlignment(.trailing)
            
            ShimmeringText(
                text: hideData ? String.stars : ((currentAmount ?? 0) * currentPrice).formatCurrency(threshold: FormattingThreshold.million),
                isDownloading: pie?.data == nil
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
            text: hideData ? String.stars : currentAmount?.formatCurrency(currency: CurrencyModel.empty) ?? "00000",
            isDownloading: pie?.data == nil
        )
        .foregroundStyle(Color.onSurfaceDimmer)
        .font(.satoshiBold(12))
        .multilineTextAlignment(.leading)
        
        ShimmeringText(
            text: hideData ? String.stars : ((currentAmount ?? 0) * currentPrice).formatCurrency(threshold: FormattingThreshold.million),
            isDownloading: pie?.data == nil
        )
        .foregroundStyle(Color.onSurfaceDimmer)
        .font(.satoshiBold(12))
        .multilineTextAlignment(.leading)
    }
    
    @ViewBuilder
    private var profitLossView: some View {
        MinimumTextSize(
            text: "Profit/Loss",
            alignment: .trailing
        ) {
            VStack(alignment: .trailing, spacing: 4) {
                PriceChangeValueView(
                    change: transactions?.getProfitValue(prices: prices, showCurrency: selectedCurrency.code),
                    hideData: hideData,
                    accessibleTimeframe: "",
                    showDirection: false,
                    isDownloading: prices.isEmpty
                )
                .multilineTextAlignment(.trailing)
                
                PriceChangePercentView(
                    change: transactions?.getProfitPercent(prices: prices, showCurrency: selectedCurrency.code),
                    size: .extraSmall,
                    accessibleTimeframe: "",
                    isDownloading: prices.isEmpty
                )
                .multilineTextAlignment(.trailing)
                .opacity(0.75)
            }
        }
        .frame(alignment: .trailing)
        .padding(.leading, 16)
    }
}
