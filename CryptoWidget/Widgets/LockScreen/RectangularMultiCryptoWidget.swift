//
//  RectangularMultiCryptoWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2023-09-10.
//

import SwiftUI
import WidgetKit

struct RectangularMultiCryptoWidget: View {
    @Environment(\.colorScheme) var scheme

    let data: [Toplist]?
    let selectedCurrency: CurrencyModel?
    let hasBoughtPro: Bool
    
    var body: some View {
        if let url = URL(string: hasBoughtPro ? data == nil ? .appName : "\(data?.first?.id ?? ""),\(data?.first?.symbol ?? "")" : "buyPro") {
            
            ZStack {
                
                AccessoryWidgetBackground()
                    .cornerRadius(8)
                
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { index in
                        let coin = data?[safely: index]
                        
                        HStack(spacing: 0) {
                            Text(coin?.symbol?.uppercased() ?? "CNCR")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxHeight: .infinity)
                            
                            Spacer(minLength: 8)
                            
                            let price = coin?.current_price ?? 0.0
                            Text(price.formatCurrency(threshold: .hundredThousand, currency: selectedCurrency ?? CurrencyModel(), maxDecimals: 4))
                                .font(.system(size: 14, weight: .medium))
                                .frame(maxHeight: .infinity)
                            
                            let symbol = coin?.price_change_percentage_7d_in_currency?.getPriceDirectionShape(currentPrice: price) ?? .priceStillTriangle
                            ScaledBezier(bezierPath: symbol )
                                .fill(Color.onSurface(for: scheme))
                                .frame(width: 12, height: 8)
                                .padding(.leading, 4)
                                .frame(maxHeight: .infinity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetURL(url)
            .minimumScaleFactor(0.5)
            /*.overlay (
                WidgetBuyProOverlay(
                    hasBoughtPro: hasBoughtPro,
                    fromLockScreen: true
                )
            )*/
        }
    }
}
