//
//  NewTransactionScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-01-23.
//

import SwiftUI
import Combine

@MainActor
struct NewSwapTransactionScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @State private var viewModel: NewSwapTransactionViewModelImp
    @State private var activeDatePicker: DateRangePickerMode?
    @State private var textfieldHeight: CGFloat = 48
    
    @State private var isSelectCoinShowing = false
    @State private var isSelectingCurrency = false
    
    init(
        transactionType: NewTransactionType,
        currencyDetail: CurrencyDataModel?,
        transaction: NewSwapTransaction?
    ) {
        _viewModel = State(wrappedValue: NewSwapTransactionViewModelImp(
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
                    VStack(alignment: .leading, spacing: 16) {
                        fromAmountField
                        
                        pricePerCoinField
                        
                        toAmountField
                        
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
                        CurrencySelected(fromScreen: .newSwapTransaction, currency: $0.currency)
                    )
                    viewModel.selectedCurrency = $0
                }
            )
        }
        .sheet(item: $activeDatePicker) { mode in
            DateRangePickerSheet(
                fromScreen: .newSwapTransaction,
                dateComponents: mode.dateComponents,
                initialDate: viewModel.date,
                dateRange: viewModel.dateRange,
                applyDate: {
                    viewModel.date = $0
                }
            )
        }
        .sheet(isPresented: $isSelectCoinShowing) {
            SearchScreen(
                screenCase: .search(list: .onlyCoins),
                fromScreen: .newSwapTransaction,
                highlightId: viewModel.toInformation.0,
                hideId: viewModel.currencyDetail?.id,
                close: { id, symbol, _ in
                    isSelectCoinShowing = false
                    guard let id, let symbol else {
                        return
                    }

                    AnalyticsManager.shared.log(
                        CurrencySelected(fromScreen: .newSwapTransaction, currency: symbol.uppercased())
                    )
                    viewModel.toInformation = (id, symbol)
                }
            )
        }
    }
    
    private var navigationTitleText: String {
        "Swapped \(viewModel.currencyDetail?.symbol?.uppercased() ?? "")"
    }
    
    private var navigationTitleAccessibilityLabel: String {
        let coinName = viewModel.currencyDetail?.name ?? viewModel.currencyDetail?.symbol?.uppercased() ?? ""
        return "Swapped \(coinName)"
    }
    
    @ViewBuilder
    private var fromAmountField: some View {
        let accessibleAmount = viewModel.fromAmount?.numberAccessible() ?? ""
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Swap From")
                .font(.satoshiMedium(14))
                .foregroundStyle(Color.onSurfaceDim)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            NumericInputField(
                input: $viewModel.fromAmount,
                placeholder: "Enter Amount",
                accessibilityValue: "Amount: \(viewModel.fromAmount == nil ? "" : "\(accessibleAmount)"). Textfield",
                trailingView: {
                    Text(viewModel.currencyDetail?.symbol?.uppercased() ?? "")
                        .font(.satoshiBold(18))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                },
                inputDidChange: { }
            )
        }
    }
    
    @ViewBuilder
    private var pricePerCoinField: some View {
        let accessiblePricePerCoin = "Unit Price: \((viewModel.fromAverageCost == nil ? viewModel.currentPrice : viewModel.fromAverageCost)?.currencyAccessible(currency: viewModel.selectedCurrency) ?? ""). Textfield"
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Unit Price (\(viewModel.currencyDetail?.symbol?.uppercased() ?? ""))")
                .font(.satoshiMedium(14))
                .foregroundStyle(Color.onSurfaceDim)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            NumericInputField(
                input: $viewModel.fromAverageCost,
                placeholder: viewModel.currentPrice.formatCurrency(threshold: FormattingThreshold.none, currency: CurrencyModel.empty),
                currency: viewModel.selectedCurrency,
                forceShowCurrency: !viewModel.selectedCurrency.suffix,
                accessibilityValue: accessiblePricePerCoin,
                trailingView: {
                    CurrencyButton(
                        currency: viewModel.selectedCurrency,
                        selectNewCurrency: {
                            AnalyticsManager.shared.log(
                                SheetOpened(fromScreen: .newSwapTransaction, sheet: .currencySelector)
                            )
                            isSelectingCurrency = true
                        }
                    )
                },
                inputDidChange: { }
            )
        }
    }
    
    @ViewBuilder
    private var toAmountField: some View {
        let accessibleAmount = viewModel.toAmount?.numberAccessible() ?? ""
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Swap To")
                .font(.satoshiMedium(14))
                .foregroundStyle(Color.onSurfaceDim)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            NumericInputField(
                input: $viewModel.toAmount,
                placeholder: "Enter Amount",
                accessibilityValue: "Amount: \(viewModel.toAmount == nil ? "" : "\(accessibleAmount)"). Textfield",
                trailingView: {
                    CurrencyButton(
                        currency: CurrencyModel(code: viewModel.toInformation.1.uppercased()),
                        selectNewCurrency: {
                            AnalyticsManager.shared.log(
                                SheetOpened(fromScreen: .newSwapTransaction, sheet: .coinSearch)
                            )
                            isSelectCoinShowing = true
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
                    SheetOpened(fromScreen: .newSwapTransaction, sheet: .newTransactionDate)
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
                    SheetOpened(fromScreen: .newSwapTransaction, sheet: .newTransactionTime)
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
            .foregroundColor(.onSurface)
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
