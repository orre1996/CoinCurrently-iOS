//
//  InlineCryptoWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2023-09-08.
//

import SwiftUI

struct InlineCryptoWidget: View {
    let data: Toplist?
    let selectedCurrency: CurrencyModel?
    
    var body: some View {
        if let url = URL(string: data?.id == nil || data?.symbol == nil ? .appName : "\(data?.id ?? ""),\(data?.symbol ?? "")" ) {
            HStack(spacing: 4) {
                let symbol = data?.symbol?.uppercased() ?? ""
                let price = data?.current_price
                let formattedPrice = price?.getFormattedString(fromThousand: true, forceMaxDigits: 4) ?? ""
                let change = data?.price_change_percentage_7d_in_currency ?? 0
                let decimals = abs(change.roundTo(places: 2)) >= 100.0 ? 1 : 2
                let decimalsFormatt = "%.\(decimals)f"
                let formattedChange = String(format: decimalsFormatt, data?.price_change_percentage_7d_in_currency ?? 0.00)
                let changeSymbol = change.roundTo(places: decimals) < 0 ? "" : "+"
                
                Text("\(symbol) \(formattedPrice) \(changeSymbol)\(formattedChange)%")
            }
            .minimumScaleFactor(0.5)
            .widgetURL(url)
        }
    }
}
