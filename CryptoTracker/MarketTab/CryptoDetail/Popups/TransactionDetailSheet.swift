//
//  EditWidgetsSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/26/25.
//

import SwiftUI

struct TransactionDetailSheet: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1

    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var buttonsHeight: CGFloat = 0
    
    let coin: Toplist?
    let transaction: NewTransaction
    let hideData: Bool
    var editTransaction: (NewTransaction) -> Void
    var deleteTransaction: (NewTransaction) -> Void
    
    private var transactionCurrency: CurrencyModel {
        CurrencyModel.allCurrencies.first(where: { $0.code.lowercased() == transaction.currency.lowercased() }) ?? SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    }
    
    private var coinName: String {
        coin?.name ?? coin?.symbol ?? ""
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
                            amountView
                        } right: {
                            unitPriceView
                        }
                        
                        statRow {
                            feesView
                        } right: {
                            totalCostView
                        }
                        
                        statRow {
                            dateView
                        } right: {
                            timeView
                        }
                    } else {
                        amountView
                        statSeparator
                        unitPriceView
                        statSeparator
                        feesView
                        statSeparator
                        totalCostView
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
            
            NewShimmeringText(
                text: "\(transaction.transactionText) \(coin?.symbol?.uppercased() ?? "0000")",
                isDownloading: coin == nil
            )
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiBold(22))
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(transaction.transactionText) \(coinName)")
    }
    
    private var amountView: some View {
        statView(
            title: "Amount",
            value: hideData
                ? String.stars
                : transaction.amount.formatCurrency(
                    threshold: FormattingThreshold.million,
                    currency: CurrencyModel.empty,
                    maxDecimals: 7
                ),
            valueAccessible: hideData
                ? "hidden"
                : "\(transaction.amount.formatCurrency(currency: CurrencyModel.empty, maxDecimals: 7, accessible: true)) \(coinName)"
        )
    }
    
    private var unitPriceView: some View {
        statView(
            title: "Unit Price",
            value: hideData
                ? String.stars
                : transaction.pricePerCoin?.formatCurrency(
                    threshold: FormattingThreshold.million,
                    currency: transactionCurrency
                ) ?? "N/A",
            valueAccessible: hideData
                ? "hidden"
                : transaction.pricePerCoin.map {
                    $0.formatCurrency(
                        threshold: FormattingThreshold.million,
                        currency: transactionCurrency,
                        accessible: true
                    )
                } ?? "Not available"
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
    
    private var totalCostView: some View {
        statView(
            title: "Total Cost",
            value: hideData
                ? String.stars
                : transaction.totalSpent.formatCurrency(
                    threshold: FormattingThreshold.million,
                    currency: transactionCurrency
                ),
            valueAccessible: hideData
                ? "hidden"
                : transaction.totalSpent.formatCurrency(
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
