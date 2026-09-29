//
//  CurrencyRowView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-18.
//

import SwiftUI

struct CurrencyRowView: View {
    @ScaledMetric private var scale: CGFloat = 1

    let currency: CurrencyModel
    let selectedCurrency: CurrencyModel
    let action: (CurrencyModel) -> Void

    var body: some View {
        Button(action: {
            action(currency)
        }) {
            HStack(spacing: 16) {
                Circle()
                    .stroke(Color.primary, lineWidth: 3)
                    .frame(width: 32 * min(scale, 1.5), height: 32 * min(scale, 1.5), alignment: .center)
                    .background(currency == selectedCurrency ? Color.primary : .clear)
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(currency.localizedName)
                        .font(.poppinsRegular(16))
                        .foregroundColor(.onSurface)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("\(currency.code) (\(currency.symbol))")
                        .font(.poppinsRegular(14))
                        .foregroundColor(Color.onSurface)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .modifier(CardBackground())
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
