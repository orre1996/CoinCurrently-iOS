//
//  WatchCurrencySelectorScreen.swift
//  CoinCurrentlyWatch Extension
//
//  Created by Oscar Berggren on 2026-09-27.
//

import SwiftUI

@MainActor
struct WatchCurrencySelectorScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel

    @State private var selectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()

    private var currencies: [CurrencyModel] {
        CurrencyModel.allCurrencies.sorted(by: { $0.currency < $1.currency })
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 8) {
                ForEach(currencies, id: \.code) { currency in
                    currencyRow(currency)
                }
            }
        }
        .navigationBarTitle("Currency")
    }

    private func currencyRow(_ currency: CurrencyModel) -> some View {
        let isSelected = selectedCurrency.code == currency.code

        return Button {
            selectedCurrency = currency
            SettingsManager.shared.set(data: currency, key: GlobalSettingKey.selectedCurrency)
            navigationViewModel.navPath.removeLast()
        } label: {
            HStack(spacing: 8) {
                Image.checkCircle
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.primary)
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.currency)
                        .font(.satoshiBold(14))
                        .foregroundStyle(Color.onSurface)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(currency.code) (\(currency.symbol))")
                        .font(.satoshiBold(12))
                        .foregroundStyle(Color.onSurfaceDim)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .background(Color.surfaceContainerHigh)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(currency.currency)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
