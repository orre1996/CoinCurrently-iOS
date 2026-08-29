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
    
    @State private var viewModel: NewTransactionViewModelImp
    @State private var showDatePicker = false
    @State private var dateComponents = DatePickerComponents.date
    @State private var textfieldHeight: CGFloat = 48
    
    @State private var isAmountEditing = false
    @State private var isAverageEditing = false
    @State private var isFeesEditing = false
    @State private var isSelectingCurrency = false
    
    init(
        transactionType: NewTransactionType,
        currencyDetail: CurrencyDataModel?,
        transaction: NewSwapTransaction?
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
                    VStack(alignment: .leading, spacing: 16) {
                        if viewModel.transactionType == .importAddress {
                            addressField
                        }
                        
                        if viewModel.transactionType != .importAddress {
                            amountField
                        }
                        
                        if !viewModel.transactionType.isTransfer && viewModel.transactionType != .importAddress {
                            HStack(alignment: .center, spacing: 16) {
                                pricePerCoinField
                                
                                transactionFeeField
                            }
                        }
                        
                        if viewModel.transactionType != .importAddress {
                            dateAndTimeFields
                        }
                        
                        noteField
                    }
                    .padding(16)
                }
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
                
                Separator()
                    .padding(.horizontal, 16)
                
                Group {
                    if let isAmountTooHigh = viewModel.isAmountTooHigh, isAmountTooHigh {
                        invalidAmountView
                    }
                    
                    if viewModel.showInvalidAddress {
                        emptyBalanceView
                    }
                }
                
                actionsView
            }
            .accessibilityHidden(showDatePicker)
            
            if showDatePicker {
                datePickerView
            }
        }
        .task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.setHasBoughtPro() }
                group.addTask { await viewModel.getCryptoDetail() }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.setHasBoughtPro() }
                        group.addTask { await viewModel.getCryptoDetail() }
                    }
                }
            default:
                break
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button("Close") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .accessibilityLabel("Close keyboard")
            }
        }
        .navigationTitle("\(viewModel.transactionType.rawValue) \(viewModel.currencyDetail?.symbol?.uppercased() ?? "")")
        .sheet(isPresented: $isSelectingCurrency) {
            CurrencyOptionsSheet(
                selectedSortOption: viewModel.selectedCurrency,
                newOptionSelected: {
                    viewModel.selectedCurrency = $0
                }
            )
        }
    }
    
    private var addressField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Address")
                .font(.poppinsRegular(14))
                .foregroundColor(.primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            HStack(spacing: 16) {
                InputField(
                    placeholder: "Address",
                    input: $viewModel.address,
                    isEditing: .constant(false),
                    accessibilityText: "Address: \(viewModel.address.isEmpty ? "" : viewModel.address). Textfield",
                    keyboardType: .default
                )
                .readSize {
                    textfieldHeight = $0.height
                }
            }
        }
    }
    
    @ViewBuilder
    private var amountField: some View {
        let accessibleAmount = viewModel.amount?.numberAccessible() ?? ""
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.poppinsRegular(14))
                .foregroundColor(.primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            NumericInputField(
                input: $viewModel.amount,
                placeholder: "Enter Amount",
                accessibilityValue: "Amount: \(viewModel.amount == nil ? "" : "\(accessibleAmount)"). Textfield",
                trailingView: {
                    CurrencyButton(
                        currency: viewModel.selectedCurrency,
                        selectNewCurrency: {
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
    private var pricePerCoinField: some View {
        let accessiblePricePerCoin = "Unit Price: \((viewModel.averageCost == nil ? viewModel.currentPrice : viewModel.averageCost)?.currencyAccessible(currency: viewModel.selectedCurrency) ?? ""). Textfield"
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Unit Price")
                .font(.poppinsRegular(14))
                .foregroundColor(.primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            NumericInputField(
                input: $viewModel.averageCost,
                placeholder: viewModel.currentPrice.formatCurrency(threshold: FormattingThreshold.none, currency: CurrencyModel.empty),
                currency: viewModel.selectedCurrency,
                accessibilityValue: accessiblePricePerCoin,
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
                .font(.poppinsRegular(14))
                .foregroundColor(.primaryTextColor)
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
                .font(.poppinsRegular(14))
                .lineLimit(1)
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
                dateComponents = .date
                showDatePicker = true
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
                .font(.poppinsRegular(14))
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
                dateComponents = .hourAndMinute
                showDatePicker = true
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
                .font(.poppinsRegular(14))
                .foregroundColor(.primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            ZStack {
                HStack(spacing: 0) {
                    Text("Enter notes (Optional)")
                        .font(.poppinsRegular(16))
                        .foregroundColor(.mainGray)
                        .opacity(viewModel.note.isEmpty ? 1 : 0)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityHidden(true)
                }
                .padding(.top, 9)
                .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
                
                UITextViewWrapper(text: $viewModel.note, calculatedHeight: .constant(88))
                    .padding(.leading, -4)
                    .accessibilityElement(children: .ignore)
                    .accessibilityHint("Double tap to edit")
                    .accessibilityLabel("\(viewModel.note.isEmpty ? "Input notes here, optional" : "Note: \(viewModel.note)"). Textfield")
            }
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
            .background(Color.clear)
            .foregroundColor(.primaryTextColor)
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .cornerRadius(8)
            .modifier(BorderModifier(color: [viewModel.note.count <= 200 ? Color.outlineVariant : Color.trendDown]))
            
            Text("\(viewModel.note.count) / 200 characters")
                .font(.poppinsRegular(12))
                .foregroundColor(viewModel.note.count <= 200 ? .primaryTextColor : .mainRed)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 8)
                .accessibilityHidden(true)
        }
    }
    
    private var invalidAmountView: some View {
        Text("You can't remove a higher amount than you have.")
            .font(.poppinsRegular(12))
            .foregroundColor(.mainRed)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(EdgeInsets(top: 16, leading: 32, bottom: 0, trailing: 32))
    }
    
    private var emptyBalanceView: some View {
        Text("Couldn't find balance for entered address. Make sure the address is correct.")
            .font(.poppinsRegular(12))
            .foregroundColor(.mainRed)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(EdgeInsets(top: 16, leading: 32, bottom: 0, trailing: 32))
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
                isLoading: viewModel.isLoadingAddress,
                fullWidth: true
            ) {
                Task {
                    if viewModel.transactionType == .importAddress {
                        if await viewModel.startGettingAddress() {
                            dismiss()
                        }
                    } else {
                        await viewModel.addTransaction()
                        dismiss()
                    }
                }
            }
            .frame(maxWidth: 400)
            .accessibilityLabel("Save: \(viewModel.isInputValid ? "" : "Disabled because invalid or no amount is entered")")
        }
        .animation(.none, value: viewModel.isInputValid)
        .padding(16)
    }
    
    private var datePickerView: some View {
        DatePickerSheet(
            date: viewModel.date,
            dateRange: viewModel.dateRange,
            dateComponents: dateComponents,
            setDate: { newDate in
                if let newDate {
                    viewModel.date = newDate
                }
            }, dismiss: {
                showDatePicker = false
            }
        )
    }
    
    private func dismiss() {
        let shouldDismissToRoot = navigationViewModel.navPath.contains {
            if case .SelectCoin = $0 { return true }
            return false
        }
        
        if shouldDismissToRoot {
            navigationViewModel.navPath = [.MainFlow]
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
