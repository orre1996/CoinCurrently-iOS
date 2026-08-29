//
//  NewTransactionScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-01-23.
//

import SwiftUI
import Combine

@MainActor
struct NewImportTransactionScreen: View {
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var viewModel = NewImportTransactionViewModelImp()
    @State private var isSelectCoinShowing = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.surface
                .ignoresSafeArea()
            
            GeometryReader { reader in
                VStack(spacing: 24) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            inputField
                            
                            nameField
                        }
                    }
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
                    
                    Separator()

                    actionButtons
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 16)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button("Close") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .accessibilityLabel("Close keyboard")
            }
        }
        .navigationTitle("Import Wallet")
        .sheet(isPresented: $isSelectCoinShowing) {
            let ethereumImage = viewModel.chainCoins?.first(where: { $0.id == "ethereum" })?.image

            SearchScreen(
                screenCase: .fixedList(
                    list: (viewModel.chainCoins ?? []) + [Toplist(id: "token", symbol: "token", name: "Ethereum Tokens", image: ethereumImage)]
                ),
                fromScreen: .newImportTransaction,
                highlightId: viewModel.selectedChain.id,
                hideId: nil,
                close: { _, symbol, _ in
                    isSelectCoinShowing = false
                    guard let symbol else {
                        return
                    }

                    AnalyticsManager.shared.log(
                        CurrencySelected(fromScreen: .newImportTransaction, currency: symbol.uppercased())
                    )
                    viewModel.selectedChain = Chain(rawValue: symbol.lowercased()) ?? .btc
                }
            )
        }
        .task {
            await viewModel.getToplist()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await viewModel.getToplist()
                }
            default:
                break
            }
        }
    }
    
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wallet Name")
                .font(.satoshiMedium(14))
                .foregroundStyle(Color.onSurfaceDim)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            TextInputField(
                input: $viewModel.walletName,
                placeholder: "Enter name (Optional)",
                accessibilityValue: viewModel.walletName.isEmpty ? "Enter wallet name, optional" : viewModel.walletName,
                leadingIcon: nil,
                outlineColor: [viewModel.walletName.count <= 40 ? Color.outlineVariant : Color.trendDown],
                inputDidChange: { },
                onCommit: { }
            )
            
            Text("\(viewModel.walletName.count) / 40 characters")
                .font(.satoshiMedium(14))
                .foregroundColor(viewModel.walletName.count <= 40 ? .onSurfaceDimmer : .trendDown)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
        }
    }
    
    private var inputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wallet Address")
                .font(.satoshiMedium(14))
                .foregroundStyle(viewModel.showImportError ? Color.trendDown : Color.onSurfaceDim)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            TextInputField(
                input: $viewModel.address,
                placeholder: "Enter address",
                accessibilityValue: viewModel.address.isEmpty ? "Enter wallet address" : viewModel.address,
                leadingIcon: nil,
                outlineColor: viewModel.showImportError ? [Color.trendDown] : [Color.outlineVariant],
                trailingView: {
                    MenuButton(
                        options: [],
                        selectedOption: viewModel.selectedChain.rawValue,
                        optionChanged: { _ in }
                    )
                    .overlay(Color.black.opacity(0.00001))
                    .onTapGesture {
                        AnalyticsManager.shared.log(
                            SheetOpened(fromScreen: .newImportTransaction, sheet: .coinSearch)
                        )
                        isSelectCoinShowing = true
                    }
                },
                inputDidChange: { },
                onCommit: { })
            
            Text(viewModel.showImportError ? "Invalid address or chain" : "Select the chain that matches your wallet.")
                .font(.satoshiMedium(14))
                .foregroundStyle(viewModel.showImportError ? Color.trendDown : Color.onSurfaceDimmer)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 8) {
            SecondaryButton(
                text: "Close",
                fullWidth: true,
                action: {
                    dismiss()
                }
            )

            PrimaryButton(
                text: "Import",
                isEnabled: !viewModel.address.isEmpty && viewModel.walletName.count <= 40,
                isLoading: viewModel.isImporting,
                fullWidth: true,
                action: {
                    Task {
                        guard await viewModel.importWallet() else {
                            return
                        }
                        
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
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
