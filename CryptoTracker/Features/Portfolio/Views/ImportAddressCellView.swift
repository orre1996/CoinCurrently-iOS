//
//  ImportAddressCellView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 11/7/25.
//

import SwiftUI

struct ImportAddressCellView: View {
    let walletImport: AddressImport?
    let symbol: String?
    let currentPrice: Double?
    let hideData: Bool
    
    let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel.´default´
    
    var body: some View {
        HStack(spacing: 0) {
            Text(walletImport?.address ?? Localization.string("Unknown"))
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
            
            Spacer(minLength: 16)
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(((Double(walletImport?.balance ?? "0") ?? 0) * (currentPrice ?? 0)).formatCurrency(
                    threshold: FormattingThreshold.million,
                    currency: currency
                ))
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
                
                ShimmeringText(
                    text: hideData ? String.stars : "+\((Double(walletImport?.balance ?? "0") ?? 0).formatCurrency(threshold: FormattingThreshold.million, currency: CurrencyModel.empty)) \(symbol?.uppercased() ?? "")",
                    isDownloading: walletImport == nil
                )
                .foregroundStyle(Color.onSurfaceDim)
                .font(.satoshiBold(12))
            }
        }
    }
}
