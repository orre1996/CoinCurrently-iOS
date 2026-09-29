//
//  CurrencyConverterView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 5/13/25.
//

import SwiftUI

struct NFTConverterView: View {
    let currentCurrency: CurrencyDataModel?
    let fromScreen: ScreenLabel
    
    @Binding var isSelectingCurrency: Bool
    @Binding var selectedCurrency: CurrencyModel

    @State private var coinAmount: Double? = 1
    @State private var valueAmount: Double? = 1

    @ScaledMetric private var scale: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            
            inputFields
                .cardBackground()
        }
        .onAppear {
            setValueAmount()
        }
        .onChange(of: currentCurrency) {
            setValueAmount()
        }
        .onChange(of: selectedCurrency) {
            setValueAmount()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button(Localization.string("Close")) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .accessibilityLabel(Localization.string("Close keyboard"))
            }
        }
    }
    
    private var headerView: some View {
        Text(Localization.string("Currency Converter"))
            .font(.satoshiBold(22))
            .foregroundStyle(Color.onSurfaceDim)
            .accessibilityAddTraits(.isHeader)
    }
    
    private var inputFields: some View {
        VStack(spacing: 16) {
            coinAmountInputField

            valueAmountInputField
        }
    }
    
    private var coinAmountInputField: some View {
        HStack(spacing: 8) {
            NumericInputField(
                input: $coinAmount,
                accessibilityValue: Localization.format(
                    "%1$@ %2$@ equals %3$@",
                    coinAmount?.formatted() ?? "",
                    currentCurrency?.name ?? "",
                    valueAmount?.formatCurrency(threshold: FormattingThreshold.none, accessible: true) ?? ""
                ),
                trailingView: {
                    symbolView
                },
                inputDidChange: {
                    setValueAmount()
                }
            )
        }
    }
    
    private var symbolView: some View {
        ZStack {
            currentCurrencyButton
                .opacity(0)
            
            HStack(spacing: 8) {
                ShimmeringImage(
                    imageUrl: currentCurrency?.image?.thumb,
                    downloading: currentCurrency?.image == nil,
                    size: 20 * min(scale, 1.5)
                )
                
                ShimmeringText(
                    text: currentCurrency?.symbol?.uppercased() ?? "0000",
                    isDownloading: currentCurrency?.symbol == nil
                )
                .font(.satoshiBold(18))
                .foregroundStyle(Color.onSurfaceDim)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .accessibilityHidden(true)
    }

    private var valueAmountInputField: some View {
        HStack(spacing: 8) {
            NumericInputField(
                input: $valueAmount,
                accessibilityValue: Localization.format(
                    "%1$@ equals %2$@ %3$@",
                    valueAmount?.formatCurrency(threshold: FormattingThreshold.none, accessible: true) ?? "",
                    coinAmount?.formatted() ?? "",
                    currentCurrency?.name ?? ""
                ),
                trailingView: {
                    currentCurrencyButton
                },
                inputDidChange: {
                    setCoinAmount()
                }
            )
        }
    }
    
    private var currentCurrencyButton: some View {
        CurrencyButton(
            currency: selectedCurrency,
            selectNewCurrency: {
                AnalyticsManager.shared.log(
                    SheetOpened(fromScreen: fromScreen, sheet: .currencySelector)
                )
                isSelectingCurrency = true
            }
        )
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    private func setCoinAmount() {
        guard let currentPrice = currentCurrency?.market_data?.current_price?.getConvertedCurrency(selectedCurrency: selectedCurrency.code) else {
            return
        }

        coinAmount = (valueAmount ?? 1) / currentPrice
    }
    
    private func setValueAmount() {
        guard let currentPrice = currentCurrency?.market_data?.current_price?.getConvertedCurrency(selectedCurrency: selectedCurrency.code) else {
            return
        }

        valueAmount = (coinAmount ?? 1) * currentPrice
    }
}
