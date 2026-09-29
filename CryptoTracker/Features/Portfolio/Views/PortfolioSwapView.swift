//
//  PortfolioTransactionView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/29/25.
//

import SwiftUI

struct PortfolioSwapView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let coin: Toplist?
    let transaction: PortfolioSwapTransaction?
    let portfolio: [Pie]?
    let hideData: Bool
    let index: Int
    let totalCount: Int
    let showTransactionDetails: () -> Void
    
    let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel.´default´
    
    private func coinName(id: String, symbol: String) -> String {
        if coin?.id == id, let name = coin?.name, !name.isEmpty {
            return name
        }
        
        if let name = portfolio?.first(where: { $0.data?.id == id })?.data?.name, !name.isEmpty {
            return name
        }
        
        return symbol
    }
    
    private var accessibilityLabelText: String {
        var components: [String] = []
        
        components.append(Localization.format("Transaction %1$d of %2$d", index + 1, totalCount))
        
        let fromName = coinName(
            id: transaction?.fromCurrencyId ?? "",
            symbol: transaction?.fromCurrencySymbol ?? ""
        )
        let toName = coinName(
            id: transaction?.toCurrencyId ?? "",
            symbol: transaction?.toCurrencySymbol ?? ""
        )
        components.append(Localization.format("Swapped %1$@ for %2$@", fromName, toName))
        
        if hideData {
            components.append(Localization.string("Amount hidden"))
        } else {
            let receivedAmount = abs(transaction?.toAmount ?? 0).formatCurrency(currency: CurrencyModel.empty, accessible: true)
            components.append(Localization.format("Received %1$@ %2$@", receivedAmount, toName).trimmingCharacters(in: .whitespaces))
            
            let sentAmount = abs(transaction?.fromAmount ?? 0).formatCurrency(currency: CurrencyModel.empty, accessible: true)
            components.append(Localization.format("Sent %1$@ %2$@", sentAmount, fromName).trimmingCharacters(in: .whitespaces))
        }
        
        if let date = transaction?.date {
            components.append(date.addedAccessibilityDescription)
        }
        
        return components.joined(separator: ". ")
    }
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ShimmeringImage(
                imageUrl: coin?.image,
                downloading: coin == nil,
                size: 28 * min(scale, 1.5)
            )
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: 4, horizontalAlignment: .leading, verticalAlignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    ShimmeringText(
                        text: Localization.format(
                            "Swapped %1$@ for %2$@",
                            transaction?.fromCurrencySymbol.uppercased() ?? "0000",
                            transaction?.toCurrencySymbol.uppercased() ?? "0000"
                        ),
                        isDownloading: transaction == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                    
                    ShimmeringText(
                        text: transaction?.date.formatted(date: .omitted, time: .shortened) ?? "000000",
                        isDownloading: transaction == nil
                    )
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .font(.satoshiBold(12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if !isHorizontal {
                    valuesSubtitleView
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if isHorizontal {
                valuesView
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(accessibilityLabelText)
        .onTapGesture {
            showTransactionDetails()
        }
    }
    
    @ViewBuilder
    private var valuesView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ShimmeringText(
                text: hideData ? String.stars : "+\(transaction?.toAmount.formatCurrency(threshold: FormattingThreshold.million, currency: CurrencyModel.empty) ?? "0000000")\(transaction?.toCurrencySymbol.uppercased() ?? "0000")",
                isDownloading: transaction == nil
            )
            .foregroundStyle(Color.onSurface)
            .font(.satoshiBold(16))
            
            ShimmeringText(
                text: hideData ? String.stars : "-\(transaction?.fromAmount.formatCurrency(threshold: FormattingThreshold.million, currency: CurrencyModel.empty) ?? "000000")\(transaction?.fromCurrencySymbol.uppercased() ?? "0000")",
                isDownloading: transaction == nil
            )
            .foregroundStyle(Color.onSurfaceDimmer)
            .font(.satoshiBold(12))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .multilineTextAlignment(.trailing)
    }
    
    @ViewBuilder
    private var valuesSubtitleView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ShimmeringText(
                text: hideData ? String.stars : "+\(transaction?.toAmount.formatCurrency(threshold: FormattingThreshold.million, currency: CurrencyModel.empty) ?? "0000000")\(transaction?.toCurrencySymbol.uppercased() ?? "0000")",
                isDownloading: transaction == nil
            )
            .foregroundStyle(Color.onSurfaceDimmer)
            .font(.satoshiBold(12))
            
            ShimmeringText(
                text: hideData ? String.stars : "-\(transaction?.fromAmount.formatCurrency(threshold: FormattingThreshold.million, currency: CurrencyModel.empty) ?? "000000")\(transaction?.fromCurrencySymbol.uppercased() ?? "0000")",
                isDownloading: transaction == nil
            )
            .foregroundStyle(Color.onSurfaceDimmer)
            .font(.satoshiBold(12))
        }
        .multilineTextAlignment(.leading)
    }
}
