//
//  NewTransactionScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-01-23.
//

import SwiftUI
import Combine

@MainActor
struct NewTransactionScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @State private var viewModel: NewTransactionViewModelImp
    @State private var activeDatePicker: DateRangePickerMode?
    @State private var textfieldHeight: CGFloat = 48
    @State private var isSelectingCurrency = false
    
    init(
        transactionType: NewTransactionType,
        currencyDetail: CurrencyDataModel?,
        transaction: NewTransaction?
    ) {
        _viewModel = State(wrappedValue: NewTransactionViewModelImp(
            transactionType: transactionType,
            currencyDetail: currencyDetail,
            transaction: transaction
        ))
    }
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.surface
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        amountField
                        
                        pricePerCoinField
                        
                        transactionFeeField
                        
                        dateAndTimeFields
                        
                        noteField
                    }
                    .padding(16)
                }
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
                
                Separator()
                    .padding(.horizontal, 16)

                actionsView
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(navigationTitleText)
                    .accessibilityLabel(navigationTitleAccessibilityLabel)
                    .accessibilityAddTraits(.isHeader)
            }
            
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button("Close") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .accessibilityLabel("Close keyboard")
            }
        }
        .task {
            await viewModel.setStartData()
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getCryptoDetail() }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await viewModel.getCryptoDetail()
                }
            default:
                break
            }
        }
        .sheet(isPresented: $isSelectingCurrency) {
            CurrencyOptionsSheet(
                selectedSortOption: viewModel.selectedCurrency,
                newOptionSelected: {
                    AnalyticsManager.shared.log(
                        CurrencySelected(fromScreen: .newPortfolioTransaction, currency: $0.currency)
                    )
                    viewModel.selectedCurrency = $0
                }
            )
        }
        .sheet(item: $activeDatePicker) { mode in
            DateRangePickerSheet(
                fromScreen: .newPortfolioTransaction,
                dateComponents: mode.dateComponents,
                initialDate: viewModel.date,
                dateRange: viewModel.dateRange,
                applyDate: {
                    viewModel.date = $0
                }
            )
        }
    }

    private var navigationTitleText: String {
        "\(viewModel.transactionType.rawValue) \(viewModel.currencyDetail?.symbol?.uppercased() ?? "")"
    }

    private var navigationTitleAccessibilityLabel: String {
        let coinName = viewModel.currencyDetail?.name ?? viewModel.currencyDetail?.symbol?.uppercased() ?? ""
        return "\(viewModel.transactionType.rawValue) \(coinName)"
    }

    @ViewBuilder
    private var amountField: some View {
        let accessibleAmount = viewModel.amount?.numberAccessible() ?? ""
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.satoshiMedium(14))
                .foregroundStyle(Color.onSurfaceDim)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            NumericInputField(
                input: $viewModel.amount,
                placeholder: "Enter Amount",
                accessibilityValue: "Amount: \(viewModel.amount == nil ? "" : "\(accessibleAmount)"). Textfield",
                trailingView: {
                    Text(viewModel.currencyDetail?.symbol?.uppercased() ?? "")
                        .font(.satoshiBold(18))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        .accessibilityHidden(true)
                },
                inputDidChange: { }
            )
        }
    }
    
    @ViewBuilder
    private var pricePerCoinField: some View {
        let accessiblePricePerCoin = "Unit Price: \((viewModel.averageCost == nil ? viewModel.currentPrice : viewModel.averageCost)?.currencyAccessible(currency: viewModel.selectedCurrency) ?? ""). Textfield"
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Unit Price")
                .font(.satoshiMedium(14))
                .foregroundStyle(Color.onSurfaceDim)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            NumericInputField(
                input: $viewModel.averageCost,
                placeholder: viewModel.currentPrice.formatCurrency(threshold: FormattingThreshold.none, currency: CurrencyModel.empty),
                currency: viewModel.selectedCurrency,
                forceShowCurrency: !viewModel.selectedCurrency.suffix,
                accessibilityValue: accessiblePricePerCoin,
                trailingView: {
                    CurrencyButton(
                        currency: viewModel.selectedCurrency,
                        selectNewCurrency: {
                            AnalyticsManager.shared.log(
                                SheetOpened(fromScreen: .newPortfolioTransaction, sheet: .currencySelector)
                            )
                            isSelectingCurrency = true
                        }
                    )
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                },
                inputDidChange: { }
            )
        }
    }
    
    @ViewBuilder
    private var transactionFeeField: some View {
        let selectedCurrency = viewModel.selectedCurrency
        let accessibleFees = "Transaction fee: \(viewModel.fees == nil ? "" : "\(viewModel.fees?.currencyAccessible(currency: selectedCurrency) ?? "")"). Textfield"
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Fees")
                .font(.satoshiMedium(14))
                .foregroundStyle(Color.onSurfaceDim)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            NumericInputField(
                input: $viewModel.fees,
                placeholder: "Enter Fees",
                currency: viewModel.selectedCurrency,
                accessibilityValue: accessibleFees,
                inputDidChange: { }
            )
        }
    }
    
    private var dateAndTimeFields: some View {
        AdaptiveStack(isHorizontal: isHorizontal, spacing: 16, horizontalAlignment: .leading, verticalAlignment: .top) {
            dateField
                .frame(maxWidth: .infinity, alignment: .leading)
            
            timeField
        }
    }
    
    @ViewBuilder
    private var dateField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date")
                .lineLimit(1)
                .font(.satoshiMedium(14))
                .foregroundStyle(Color.onSurfaceDim)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            TextInputField(
                input: .constant(viewModel.date.formatted(.dateTime.month(.abbreviated).day().year())),
                accessibilityValue: viewModel.date.formatted(.dateTime.month(.abbreviated).day().year()),
                leadingIcon: .date,
                inputDidChange: { },
                onCommit: { }
            )
            .allowsHitTesting(false)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.endEditing()
                AnalyticsManager.shared.log(
                    SheetOpened(fromScreen: .newPortfolioTransaction, sheet: .newTransactionDate)
                )
                activeDatePicker = .date
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Date: \(viewModel.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year()))")
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Double tap to change date")
        }
    }
    
    @ViewBuilder
    private var timeField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time")
                .lineLimit(1)
                .font(.satoshiMedium(14))
                .foregroundStyle(Color.onSurfaceDim)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            TextInputField(
                input: .constant(viewModel.date.formatted(date: .omitted, time: .shortened)),
                accessibilityValue: viewModel.date.formatted(date: .omitted, time: .shortened),
                leadingIcon: .time,
                fillWidth: !isHorizontal,
                inputDidChange: { },
                onCommit:  { }
            )
            .allowsHitTesting(false)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.endEditing()
                AnalyticsManager.shared.log(
                    SheetOpened(fromScreen: .newPortfolioTransaction, sheet: .newTransactionTime)
                )
                activeDatePicker = .time
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Time: \(viewModel.date.formatted(date: .omitted, time: .shortened))")
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Double tap to change time")
            .background(Color.black.opacity(0.0001))
        }
        .accessibilityElement(children: .contain)
        .frame(maxWidth: isHorizontal ? nil : .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.satoshiMedium(14))
                .foregroundStyle(Color.onSurfaceDim)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            ZStack {
                HStack(spacing: 0) {
                    Text("Enter notes (Optional)")
                        .font(.satoshiRegular(16))
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .opacity(viewModel.note.isEmpty ? 1 : 0)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityHidden(true)
                }
                .padding(.top, 16)
                .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
                
                UITextViewWrapper(text: $viewModel.note, calculatedHeight: .constant(132))
                    .padding(.leading, -4)
                    .accessibilityElement(children: .ignore)
                    .accessibilityHint("Double tap to edit")
                    .accessibilityLabel("\(viewModel.note.isEmpty ? "Input notes here, optional" : "Note: \(viewModel.note)"). Textfield")
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .background(Color.clear)
            .foregroundStyle(Color.onSurface)
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .cornerRadius(8)
            .modifier(BorderModifier(color: [viewModel.note.count <= 200 ? Color.outlineVariant : Color.trendDown]))
            
            Text("\(viewModel.note.count) / 200 characters")
                .font(.satoshiMedium(14))
                .foregroundColor(viewModel.note.count <= 200 ? .onSurfaceDimmer : .trendDown)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
        }
    }

    private var actionsView: some View {
        HStack(spacing: 8) {
            SecondaryButton(
                text: "Cancel",
                fullWidth: true,
                action: {
                    dismiss()
                }
            )
            .frame(maxWidth: 400)
            
            PrimaryButton(
                text: "Save",
                isEnabled: viewModel.isInputValid,
                fullWidth: true
            ) {
                Task {
                    await viewModel.addTransaction()
                    dismiss()
                }
            }
            .frame(maxWidth: 400)
            .accessibilityLabel("Save: \(viewModel.isInputValid ? "" : "Disabled because invalid or no amount is entered")")
        }
        .animation(.none, value: viewModel.isInputValid)
        .padding(
            EdgeInsets(
                top: 24,
                leading: 16,
                bottom: 24,
                trailing: 16
            )
        )
    }
    
    private func dismiss() {
        let shouldDismissToRoot = navigationViewModel.navPath.contains {
            if case .Search = $0 { return true }
            return false
        }
        
        if shouldDismissToRoot {
            navigationViewModel.navPath = [.MainFlow]
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
