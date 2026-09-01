//
//  PortfolioImportView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 11/7/25.
//

import SwiftUI

struct PortfolioImportView: View {
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
        
        components.append("Wallet \(index + 1) of \(totalCount)")
        
        let walletName = walletImport?.walletName ?? "Imported"
        components.append(walletName)
        
        let coinName = coin?.name ?? coin?.symbol ?? ""
        if !coinName.isEmpty, let walletImport {
            components.append("\(coinName) Mainnet, \(walletImport.accessibilityAddressDescription)")
        }
        
        if hideData {
            components.append("Value hidden")
        } else if let value = walletImport?.totalValue(mainId: coin?.id, prices: prices) {
            components.append("Value \(value.formatAccessibleCurrency(currency: currency))")
        }
        
        return components.joined(separator: ". ")
    }
        
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                ShimmeringImage(
                    imageUrl: coin?.image,
                    downloading: coin == nil,
                    size: 24 * min(scale, 1.5)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    NewShimmeringText(
                        text: "\(walletImport?.walletName ?? "Imported")",
                        isDownloading: coin == nil
                    )
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                    
                    NewShimmeringText(
                        text: "\(coin?.symbol?.uppercased() ?? "") Mainnet · \(walletImport?.address.uppercased().prefix(4) ?? "")...\(walletImport?.address.uppercased().suffix(4) ?? "")",
                        isDownloading: coin == nil
                    )
                    .foregroundStyle(Color.onSurfaceDim)
                    .font(.satoshiBold(12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                NewShimmeringText(
                    text: hideData ? String.stars : walletImport?.totalValue(
                        mainId: coin?.id,
                        prices: prices
                    )?.formatCurrency(
                        threshold: FormattingThreshold.million,
                        currency: currency
                    ) ?? "",
                    isDownloading: coin?.symbol == nil
                )
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
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
