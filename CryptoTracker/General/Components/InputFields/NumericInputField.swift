//
//  NumericInputField.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 5/13/25.
//

import SwiftUI

struct NumericInputField<Content: View>: View {
    @Binding var input: Double?
    let placeholder: String
    let accessibilityValue: String
    let currency: CurrencyModel
    let forceShowCurrency: Bool
    let trailingView: () -> Content
    let inputDidChange: () -> Void
    
    @FocusState private var isFocused: Bool
    
    init(
        input: Binding<Double?>,
        placeholder: String = "Enter a number",
        currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel(),
        forceShowCurrency: Bool = false,
        accessibilityValue: String,
        @ViewBuilder trailingView: @escaping () -> Content = { EmptyView() },
        inputDidChange: @escaping () -> Void
    ) {
        self._input = input
        self.placeholder = placeholder
        self.currency = currency
        self.forceShowCurrency = forceShowCurrency
        self.accessibilityValue = accessibilityValue
        self.trailingView = trailingView
        self.inputDidChange = inputDidChange
    }
    
    @State private var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.currencySymbol = ""
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 10
        return numberFormatter
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            if Content.self == EmptyView.self && !currency.suffix || forceShowCurrency {
                Text(currency.symbol)
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .accessibilityHidden(true)
            }
            
            TextField(
                placeholder,
                value: $input,
                formatter: numberFormatter,
                prompt: Text(placeholder).foregroundColor(Color.onSurfaceDimmer)
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .focused($isFocused)
            .accessibilityValue(accessibilityValue)
            
            if Content.self != EmptyView.self {
                trailingView()
            } else if currency.suffix {
                Text(currency.symbol)
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurfaceDimmer)
            }
        }
        .font(.satoshiBold(16))
        .foregroundStyle(Color.onSurface)
        .keyboardType(.decimalPad)
        .padding(
            EdgeInsets(
                top: 16,
                leading: 16,
                bottom: 16,
                trailing: 16
            )
        )
        .background(Color.surface)
        .roundedBorderModifier()
        .onChange(of: input) {
            inputDidChange()
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }
}
