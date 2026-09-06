//
//  EditWidgetsSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/26/25.
//

import SwiftUI

struct SwapDetailSheet: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var buttonsHeight: CGFloat = 0
    
    let coin: Toplist?
    let transaction: PortfolioSwapTransaction
    let portfolio: [Pie]?
    let hideData: Bool
    var editTransaction: (PortfolioSwapTransaction) -> Void
    var deleteTransaction: (PortfolioSwapTransaction) -> Void
    
    private var transactionCurrency: CurrencyModel {
        CurrencyModel.allCurrencies.first(where: { $0.code.lowercased() == transaction.selectedCurrency.lowercased() }) ?? SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    }
    
    private var fromCoinName: String {
        coinName(id: transaction.fromCurrencyId, symbol: transaction.fromCurrencySymbol)
    }
    
    private var toCoinName: String {
        coinName(id: transaction.toCurrencyId, symbol: transaction.toCurrencySymbol)
    }
    
    private func coinName(id: String, symbol: String) -> String {
        if coin?.id == id, let name = coin?.name, !name.isEmpty {
            return name
        }
        
        if let name = portfolio?.first(where: { $0.data?.id == id })?.data?.name, !name.isEmpty {
            return name
        }
        
        return symbol
    }
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    @ViewBuilder
    private func statView(
        title: String,
        titleAccessible: String? = nil,
        value: String,
        valueAccessible: String? = nil
    ) -> some View {
        let accessibleTitle = titleAccessible ?? title
        
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityHidden(valueAccessible != nil)
            
            Text(value)
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
                .accessibilityHidden(valueAccessible != nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .if(valueAccessible != nil) { view in
            view
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(accessibleTitle): \(valueAccessible ?? "")")
        }
        .if(valueAccessible == nil) { view in
            view.accessibilityElement(children: .combine)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandler()
                .padding(
                    EdgeInsets(
                        top: 16,
                        leading: 0,
                        bottom: 8,
                        trailing: 0
                    )
                )
            
            HStack(spacing: 0) {
                headerView
                
                Spacer(minLength: 16)

                CloseButton {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(
                EdgeInsets(
                    top: 0,
                    leading: 16,
                    bottom: 24,
                    trailing: 16
                )
            )
            .readSize {
                headerHeight = $0.height
            }
            
            Separator()
                .padding(.horizontal, 16)
            
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: isHorizontal ? 16 : 0) {
                    if isHorizontal {
                        statRow {
                            swappedFromView
                        } right: {
                            swappedToView
                        }
                        
                        statRow {
                            fromUnitPriceView
                        } right: {
                            toUnitPriceView
                        }
                        
                        statRow {
                            rateView
                        } right: {
                            feesView
                        }
                        
                        statRow {
                            swappedValueView
                        } right: {
                            dateView
                        }
                        
                        timeView
                    } else {
                        swappedFromView
                        statSeparator
                        swappedToView
                        statSeparator
                        fromUnitPriceView
                        statSeparator
                        toUnitPriceView
                        statSeparator
                        rateView
                        statSeparator
                        feesView
                        statSeparator
                        swappedValueView
                        statSeparator
                        dateView
                        statSeparator
                        timeView
                    }
                    
                    if !transaction.note.isEmpty {
                        if isHorizontal {
                            Separator()
                                .padding(.top, 8)
                        } else {
                            statSeparator
                        }
                        
                        notesView
                    }
                }
                .padding(
                    EdgeInsets(
                        top: 24,
                        leading: 16,
                        bottom: transaction.note.isEmpty ? 24 : 16,
                        trailing: 16
                    )
                )
                .readSize {
                    contentHeight = $0.height
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            
            VStack(spacing: 0) {
                Separator()
                    .padding(.horizontal, 16)
                
                actionButtons
            }
            .readSize {
                buttonsHeight = $0.height
            }
        }
        .presentationDetents([.height(max(1, headerHeight + contentHeight + buttonsHeight + 32 - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private var statSeparator: some View {
        Separator()
            .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func statRow<Left: View, Right: View>(
        @ViewBuilder left: () -> Left,
        @ViewBuilder right: () -> Right
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            left()
            right()
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 8) {
            ShimmeringImage(
                imageUrl: coin?.image,
                downloading: coin == nil,
                size: 24 * min(scale, 1.5)
            )
            
            ShimmeringText(
                text: "Swapped \(transaction.fromCurrencySymbol.uppercased()) for \(transaction.toCurrencySymbol.uppercased())",
                isDownloading: coin == nil
            )
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiBold(22))
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Swapped \(fromCoinName) for \(toCoinName)")
    }
    
    private var swappedFromView: some View {
        statView(
            title: "Swapped From",
            value: hideData
                ? String.stars
                : "\(transaction.fromAmount.formatCurrency(threshold: FormattingThreshold.million, currency: CurrencyModel.empty, maxDecimals: 7))\(transaction.fromCurrencySymbol.uppercased())",
            valueAccessible: hideData
                ? "hidden"
                : "\(transaction.fromAmount.formatCurrency(currency: CurrencyModel.empty, maxDecimals: 7, accessible: true)) \(fromCoinName)"
        )
    }
    
    private var swappedToView: some View {
        statView(
            title: "Swapped To",
            value: hideData
                ? String.stars
                : "\(transaction.toAmount.formatCurrency(threshold: FormattingThreshold.million, currency: CurrencyModel.empty, maxDecimals: 7))\(transaction.toCurrencySymbol.uppercased())",
            valueAccessible: hideData
                ? "hidden"
                : "\(transaction.toAmount.formatCurrency(currency: CurrencyModel.empty, maxDecimals: 7, accessible: true)) \(toCoinName)"
        )
    }
    
    private var fromUnitPriceView: some View {
        statView(
            title: "Unit Price (\(transaction.fromCurrencySymbol.uppercased()))",
            titleAccessible: "Unit Price, \(fromCoinName)",
            value: hideData
                ? String.stars
                : transaction.fromUnitPrice.formatCurrency(
                    threshold: FormattingThreshold.million,
                    currency: transactionCurrency
                ),
            valueAccessible: hideData
                ? "hidden"
                : transaction.fromUnitPrice.formatCurrency(
                    threshold: FormattingThreshold.million,
                    currency: transactionCurrency,
                    accessible: true
                )
        )
    }
    
    private var toUnitPriceView: some View {
        statView(
            title: "Unit Price (\(transaction.toCurrencySymbol.uppercased()))",
            titleAccessible: "Unit Price, \(toCoinName)",
            value: hideData
                ? String.stars
                : transaction.toUnitPrice.formatCurrency(
                    threshold: FormattingThreshold.million,
                    currency: transactionCurrency
                ),
            valueAccessible: hideData
                ? "hidden"
                : transaction.toUnitPrice.formatCurrency(
                    threshold: FormattingThreshold.million,
                    currency: transactionCurrency,
                    accessible: true
                )
        )
    }
    
    private var rateView: some View {
        let rate = transaction.toAmount / transaction.fromAmount
        let formattedRate = rate.formatCurrency(
            threshold: FormattingThreshold.million,
            currency: CurrencyModel.empty,
            maxDecimals: 7
        )
        
        return statView(
            title: "Rate",
            value: "1 \(transaction.fromCurrencySymbol.uppercased()) = \(hideData ? String.stars : formattedRate) \(transaction.toCurrencySymbol.uppercased())",
            valueAccessible: hideData
                ? "hidden"
                : "1 \(fromCoinName) equals \(rate.formatCurrency(threshold: FormattingThreshold.million, currency: CurrencyModel.empty, maxDecimals: 7, accessible: true)) \(toCoinName)"
        )
    }

    
    private var feesView: some View {
        statView(
            title: "Fee",
            value: hideData
                ? String.stars
                : transaction.fee.formatCurrency(
                    threshold: FormattingThreshold.million,
                    currency: transactionCurrency
                ),
            valueAccessible: hideData
                ? "hidden"
                : transaction.fee.formatCurrency(
                    threshold: FormattingThreshold.million,
                    currency: transactionCurrency,
                    accessible: true
                )
        )
    }
    
    private var swappedValueView: some View {
        let swappedValue = transaction.fromAmount * transaction.fromUnitPrice
        
        return statView(
            title: "Swapped Value",
            value: hideData
                ? String.stars
                : swappedValue.formatCurrency(
                    threshold: FormattingThreshold.million,
                    currency: transactionCurrency
                ),
            valueAccessible: hideData
                ? "hidden"
                : swappedValue.formatCurrency(
                    threshold: FormattingThreshold.million,
                    currency: transactionCurrency,
                    accessible: true
                )
        )
    }
    
    private var dateView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Date")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
            
            Text(transaction.date.formatted(.dateTime.month(.abbreviated).day().year()))
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
    
    private var timeView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Time")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
            
            Text(transaction.date.formatted(date: .omitted, time: .shortened))
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
    
    private var notesView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notes")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)
            
            Text(transaction.note)
                .foregroundStyle(Color.onSurface)
                .font(.satoshiRegular(16))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var actionButtons: some View {
        AdaptiveStack(isHorizontal: isHorizontal, spacing: 8) {
            SecondaryButton(
                text: "Delete",
                icon: .delete,
                fullWidth: true,
                opaqueBackground: true,
                action: {
                    deleteTransaction(transaction)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            
            SecondaryButton(
                text: "Edit",
                icon: .edit,
                fullWidth: true,
                opaqueBackground: true,
                action: {
                    editTransaction(transaction)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .padding(
            EdgeInsets(
                top: 24,
                leading: 16,
                bottom: 24,
                trailing: 16
            )
        )
    }
}
