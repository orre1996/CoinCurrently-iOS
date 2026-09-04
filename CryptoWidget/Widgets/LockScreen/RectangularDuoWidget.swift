//
//  RectangularDuoWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2023-09-10.
//

import SwiftUI
import WidgetKit

struct RectangularDuoWidget: View {
    @Environment(\.colorScheme) var scheme

    let data: [Toplist]?
    let selectedCurrency: CurrencyModel?
    let hasBoughtPro: Bool
    
    var body: some View {
        if let url = URL(string: hasBoughtPro ? data == nil ? .appName : "\(data?.first?.id ?? ""),\(data?.first?.symbol ?? "")" : "buyPro") {
            
            ZStack {
                
                AccessoryWidgetBackground()
                    .cornerRadius(8)
                
                HStack(spacing: 4) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(data?.first?.symbol?.uppercased() ?? "CNCR")
                            .frame(maxHeight: .infinity)
                        
                        Text(data?.first?.current_price?.formatCurrency(threshold: .thousand, currency: selectedCurrency ?? CurrencyModel(), maxDecimals: 4) ?? "$0.00")
                            .frame(maxHeight: .infinity)
                        
                        let firstChange = data?.first?.price_change_percentage_7d_in_currency ?? 0
                        let firstDecimals = abs(firstChange.roundTo(places: 2)) >= 100.0 ? "%.1f" : "%.2f"
                        let firstFormattedChange = String(format: firstDecimals, data?.first?.price_change_percentage_7d_in_currency ?? 0.00)
                        let firstChangeSymbol = firstChange < 0 ? "" : "+"
                        
                        Text("\(String.preferredTimeFrameText) \(firstChangeSymbol)\(firstFormattedChange)%")
                            .frame(maxHeight: .infinity)
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(data?[safely: 1]?.symbol?.uppercased() ?? "CNCR")
                            .frame(maxHeight: .infinity)
                        
                        Text(data?[safely: 1]?.current_price?.formatCurrency(threshold: .thousand, currency: selectedCurrency ?? CurrencyModel(), maxDecimals: 4) ?? "$0.00")
                            .frame(maxHeight: .infinity)
                        
                        let secondChange = data?[safely: 1]?.price_change_percentage_7d_in_currency ?? 0
                        let decimals = abs(secondChange.roundTo(places: 2)) >= 100.0 ? 1 : 2
                        let secondDecimals = "%.\(decimals)f"
                        let secondFormattedChange = String(format: secondDecimals, data?[safely: 1]?.price_change_percentage_7d_in_currency ?? 0.00)
                        let secondChangeSymbol = secondChange.roundTo(places: decimals) < 0 ? "" : "+"
                        
                        Text("\(String.preferredTimeFrameText) \(secondChangeSymbol)\(secondFormattedChange)%")
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(4)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .font(.system(size: 12, weight: .semibold))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .widgetURL(url)
            /*.overlay (
                BuyProView(
                    hasBoughtPro: hasBoughtPro,
                    fromLockScreen: true
                )
            )*/
        }
    }
}
