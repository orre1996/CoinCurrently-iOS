//
//  PortfolioImportView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 11/7/25.
//

import SwiftUI

struct PortfolioImportTransaction: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let coin: Toplist?
    let walletImport: AddressImport?
    let prices: [Cryptocurrency]?
    let hideData: Bool
    let index: Int
    let totalCount: Int
    let showTransactionDetails: () -> Void
    
    let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel.´default´
    
    private var accessibilityLabelText: String {
        var components: [String] = []
        
        components.append("Transaction \(index + 1) of \(totalCount)")
        
        let walletName = walletImport?.walletName ?? ""
        components.append("Imported \(walletName)".trimmingCharacters(in: .whitespaces))
        
        let coinName = coin?.name ?? coin?.symbol ?? ""
        if !coinName.isEmpty, let walletImport {
            components.append("\(coinName) Mainnet, \(walletImport.accessibilityAddressDescription)")
        }
        
        if hideData {
            components.append("Value hidden")
        } else if let value = walletImport?.totalValue(mainId: coin?.id, prices: prices) {
            components.append("Value \(value.formatAccessibleCurrency(currency: currency))")
        }
        
        if let date = walletImport?.date {
            components.append(date.addedAccessibilityDescription)
        }
        
        return components.joined(separator: ". ")
    }
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    private var formattedValue: String {
        hideData ? String.stars : walletImport?.totalValue(
            mainId: coin?.id,
            prices: prices
        )?.formatCurrency(
            threshold: FormattingThreshold.million,
            currency: currency
        ) ?? ""
    }
        
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Image.walletImport
                    .resizable()
                    .frame(width: 16 * min(scale, 1.5), height: 16 * min(scale, 1.5))
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .padding(6)
                    .background(Color.surfaceContainerLow)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.outlineVariant, lineWidth: 1)
                    )
                
                AdaptiveStack(isHorizontal: isHorizontal, spacing: 4, horizontalAlignment: .leading, verticalAlignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        NewShimmeringText(
                            text: "Imported \(walletImport?.walletName ?? "")",
                            isDownloading: coin == nil
                        )
                        .foregroundStyle(Color.onSurface)
                        .font(.satoshiBold(16))
                        
                        NewShimmeringText(
                            text: "\(coin?.symbol?.uppercased() ?? "") Mainnet · \(walletImport?.address.uppercased().prefix(4) ?? "")...\(walletImport?.address.uppercased().suffix(4) ?? "")",
                            isDownloading: coin == nil
                        )
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .font(.satoshiBold(12))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !isHorizontal {
                        NewShimmeringText(
                            text: formattedValue,
                            isDownloading: coin?.symbol == nil
                        )
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .font(.satoshiBold(12))
                        .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if isHorizontal {
                    NewShimmeringText(
                        text: formattedValue,
                        isDownloading: coin?.symbol == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .multilineTextAlignment(.trailing)
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
    }
}
