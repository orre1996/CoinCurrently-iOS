//
//  PortfolioTransactionView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/29/25.
//

import SwiftUI

struct PortfolioTransactionView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let coin: Toplist?
    let transaction: NewTransaction?
    let prices: [String: Double]?
    let hideData: Bool
    let index: Int
    let totalCount: Int
    let showTransactionDetails: () -> Void
    
    let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel.´default´
    
    private var transactionCurrency: CurrencyModel {
        CurrencyModel.allCurrencies.filter({ $0.code == transaction?.currency }).first ?? currency
    }
    
    private var accessibilityLabelText: String {
        var components: [String] = []
        
        components.append("Transaction \(index + 1) of \(totalCount)")
        
        let typeText = transaction?.transactionText ?? ""
        let coinName = coin?.name ?? coin?.symbol ?? ""
        let summary = "\(typeText) \(coinName)".trimmingCharacters(in: .whitespaces)
        
        if !summary.isEmpty {
            components.append(summary)
        }
        
        if hideData {
            components.append("Value hidden")
            components.append("Amount hidden")
        } else {
            let value = (transaction?.amount ?? 0) * (currentPrice ?? 0)
            components.append("Value \(value.formatAccessibleCurrency(currency: transactionCurrency))")
            
            let prefix = transaction?.isAddOrInTransferTransaction == true ? "Plus" : "Minus"
            let amountText = abs(transaction?.amount ?? 0).formatCurrency(currency: CurrencyModel.empty, accessible: true)
            let symbol = coin?.symbol ?? ""
            components.append("\(prefix) \(amountText) \(symbol)".trimmingCharacters(in: .whitespaces))
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
        let currency = transactionCurrency
        
        HStack(alignment: .top, spacing: 8) {
            ShimmeringImage(
                imageUrl: coin?.image,
                downloading: coin == nil,
                size: 28 * min(scale, 1.5)
            )
            
            AdaptiveStack(isHorizontal: isHorizontal, spacing: 4, horizontalAlignment: .leading, verticalAlignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    NewShimmeringText(
                        text: "\(transaction?.transactionText ?? "00000000") \(coin?.symbol?.uppercased() ?? "0000")",
                        isDownloading: transaction == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                    
                    NewShimmeringText(
                        text: transaction?.date.formatted(date: .omitted, time: .shortened) ?? "000000",
                        isDownloading: transaction == nil
                    )
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .font(.satoshiBold(12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if !isHorizontal {
                    valuesSubtitleView(currency: currency)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if isHorizontal {
                valuesView(currency: currency)
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
    private func valuesView(currency: CurrencyModel) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            NewShimmeringText(
                text: hideData ? String.stars : ((transaction?.amount ?? 0) * (currentPrice ?? 0)).formatCurrency(
                    threshold: FormattingThreshold.million,
                    currency: currency
                ),
                isDownloading: transaction == nil
            )
            .foregroundStyle(Color.onSurface)
            .font(.satoshiBold(16))
            
            NewShimmeringText(
                text: hideData ? String.stars : "\(transaction?.getTransactionPrefixSign ?? "")\(transaction?.amount.formatCurrency(threshold: FormattingThreshold.million, currency: CurrencyModel.empty) ?? "000000")\(coin?.symbol?.uppercased() ?? "")",
                isDownloading: transaction == nil
            )
            .foregroundStyle(Color.onSurfaceDimmer)
            .font(.satoshiBold(12))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .multilineTextAlignment(.trailing)
    }
    
    @ViewBuilder
    private func valuesSubtitleView(currency: CurrencyModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            NewShimmeringText(
                text: hideData ? String.stars : ((transaction?.amount ?? 0) * (currentPrice ?? 0)).formatCurrency(
                    threshold: FormattingThreshold.million,
                    currency: currency
                ),
                isDownloading: transaction == nil
            )
            .foregroundStyle(Color.onSurfaceDimmer)
            .font(.satoshiBold(12))
            
            NewShimmeringText(
                text: hideData ? String.stars : "\(transaction?.getTransactionPrefixSign ?? "")\(transaction?.amount.formatCurrency(threshold: FormattingThreshold.million, currency: CurrencyModel.empty) ?? "000000")\(coin?.symbol?.uppercased() ?? "")",
                isDownloading: transaction == nil
            )
            .foregroundStyle(Color.onSurfaceDimmer)
            .font(.satoshiBold(12))
        }
        .multilineTextAlignment(.leading)
    }
    
    var currentPrice: Double? {
        if transaction?.currency == currency.code {
            return coin?.sparkline_in_7d?.price.last
        } else {
            return prices?[transaction?.currency.lowercased() ?? "usd"]
        }
    }
}
