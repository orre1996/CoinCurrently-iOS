//
//  CurrencyButton.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-04-20.
//

import SwiftUI

struct CurrencyButton: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    let currency: CurrencyModel
    let selectNewCurrency: () -> Void
    
    var body: some View {
        Button(action: {
            selectNewCurrency()
        }, label: {
            HStack(spacing: 8) {
                Text(currency.code.uppercased())
                    .font(.satoshiBold(18))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .foregroundStyle(Color.onSurfaceContainer)
                    .fixedSize(horizontal: false, vertical: true)
                
                Image.trendDown
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.onSurfaceContainer)
                    .scaledToFill()
                    .frame(width: 20 * min(scale, 1.5), height: 20 * min(scale, 1.5))
            }
        })
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Localization.format("Change currency, currently selected: %@", currency.currency))
    }
}
