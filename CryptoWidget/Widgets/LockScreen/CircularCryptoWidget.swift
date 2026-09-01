//
//  CircularCryptoWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2023-09-08.
//

import SwiftUI
import WidgetKit

struct CircularCryptoWidget: View {
    let data: Toplist?
    let selectedCurrency: CurrencyModel?
    
    var body: some View {
        if let url = URL(string: data?.id == nil || data?.symbol == nil ? .appName : "\(data?.id ?? ""),\(data?.symbol ?? "")" ) {
            
            ZStack {
                
                AccessoryWidgetBackground()
                
                VStack(spacing: 0) {
                    Text(data?.symbol?.uppercased() ?? "CNCR")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 2)
                    
                    let currentPrice = data?.current_price ?? 0
                    Text(currentPrice.getFormattedString(fromMillion: true, selectedCurrency: CurrencyModel(currency: "", code: "", symbol: "", suffix: true), forceMaxDigits: currentPrice < 100 ? 4 : 0))
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.top, data == nil ? 0 : -1)
                    
                    let decimals = abs(data?.price_change_percentage_7d_in_currency?.roundTo(places: 2) ?? 0) >= 100.0 ? 1 : 2
                    let change = data?.price_change_percentage_7d_in_currency ?? 0.00
                    let decimalsFormatted = "%.\(decimals)f"
                    let formattedChange = "\(String(format: decimalsFormatted, change))"
                    let symbol = data?.price_change_percentage_7d_in_currency?.roundTo(places: decimals) ?? 0 < 0 ? "" : "+"
                    
                    Text("\(symbol)\(formattedChange)%")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 7)
                }
                .padding(.top, -2)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
            .widgetURL(url)
        }
    }
}
