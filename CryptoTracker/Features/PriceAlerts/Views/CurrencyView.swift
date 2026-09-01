//
//  CurrencyView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-20.
//

import SwiftUI

struct CurrencyView: View {
    let currency: CurrencyModel
    let action: (CurrencyModel) -> Void

    var body: some View {
        Button(action: {
            action(currency)
        }) {
            VStack(alignment: .leading) {
                Text(currency.currency)
                    .font(.poppinsRegular(16))
                    .foregroundColor(.onSurface)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(currency.code) (\(currency.symbol))")
                    .font(.poppinsRegular(14))
                    .foregroundColor(Color.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .modifier(CardBackground())
        .padding(.horizontal, 16)
    }
}
