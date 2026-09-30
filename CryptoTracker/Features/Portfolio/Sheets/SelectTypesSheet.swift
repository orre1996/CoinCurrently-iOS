//
//  SelectDateSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/13/26.
//

import SwiftUI

struct SelectTypesSheet: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category

    @ScaledMetric private var scale: CGFloat = 1

    let fromScreen: ScreenLabel
    @Binding var transactionTypes: [PortfolioTransactionType]
    
    @State private var contentHeight: CGFloat = 0
    @State private var headerHeight: CGFloat = 0
    @State private var buttonsHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: Localization.string("Filter By Type"))
                .readSize {
                    headerHeight = $0.height
                }
            
            Separator()
                .padding(.horizontal, 16)
            
            ScrollView(.vertical) {
                bodyView
            }
            .scrollBounceBehavior(.basedOnSize)
            
            Separator()
                .padding(.horizontal, 16)
            
            actionButtons
                .readSize {
                    buttonsHeight = $0.height
                }
        }
        .presentationDetents([.height(max(1, contentHeight + headerHeight + buttonsHeight - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private var bodyView: some View {
        VStack(alignment: .leading, spacing: 4) {
            TransactionTypeView(
                title: Localization.string("Import Wallet"),
                subtitle: Localization.string("Imported a crypto wallet."),
                image: .walletImport,
                isMultiSelectEnabled: true,
                isSelected: transactionTypes.contains(.importAddress),
                viewTapped: {
                    toggleType(.importAddress)
                }
            )
            
            TransactionTypeView(
                title: Localization.string("Buy"),
                subtitle: Localization.string("Bought coins with cash."),
                image: .plus,
                isMultiSelectEnabled: true,
                isSelected: transactionTypes.contains(.buy),
                viewTapped: {
                    toggleType(.buy)
                }
            )
            
            TransactionTypeView(
                title: Localization.string("Sell"),
                subtitle: Localization.string("Sold coins with cash."),
                image: .minus,
                isMultiSelectEnabled: true,
                isSelected: transactionTypes.contains(.sell),
                viewTapped: {
                    toggleType(.sell)
                }
            )
            
            TransactionTypeView(
                title: Localization.string("Swap"),
                subtitle: Localization.string("Swapped one coin for another."),
                image: .trade,
                isMultiSelectEnabled: true,
                isSelected: transactionTypes.contains(.swap),
                viewTapped: {
                    toggleType(.swap)
                }
            )
            
            TransactionTypeView(
                title: Localization.string("Deposit"),
                subtitle: Localization.string("Deposited coins into your wallet."),
                image: .deposit,
                isMultiSelectEnabled: true,
                isSelected: transactionTypes.contains(.transferIn),
                viewTapped: {
                    toggleType(.transferIn)
                }
            )
            
            TransactionTypeView(
                title: Localization.string("Withdraw"),
                subtitle: Localization.string("Withdrawn coins out of your wallet."),
                image: .withdraw,
                isMultiSelectEnabled: true,
                isSelected: transactionTypes.contains(.transferOut),
                viewTapped: {
                    toggleType(.transferOut)
                }
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(
            EdgeInsets(
                top: 24,
                leading: 16,
                bottom: 24,
                trailing: 16
            )
        )
        .readSize {
            contentHeight = $0.height
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact

        AdaptiveStack(isHorizontal: isHorizontal, spacing: 12) {
            SecondaryButton(
                text: Localization.string("Clear"),
                accessibilityLabel: Localization.string("Clear filters"),
                fullWidth: true,
                opaqueBackground: true,
                action: {
                    if !transactionTypes.isEmpty {
                        AnalyticsManager.shared.log(
                            TransactionTypeFilterCleared(fromScreen: fromScreen)
                        )
                    }
                    transactionTypes.removeAll()
                }
            )
            
            PrimaryButton(
                text: Localization.string("Apply"),
                accessibilityLabel: Localization.string("Apply filters"),
                fullWidth: true,
                opaqueBackground: true,
                action: {
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
    
    private func toggleType(_ type: PortfolioTransactionType) {
        if transactionTypes.contains(type) {
            transactionTypes.removeAll(where: { $0 == type })
            AnalyticsManager.shared.log(
                TransactionTypeFilterRemoved(
                    fromScreen: fromScreen,
                    transactionType: type.rawValue
                )
            )
        } else {
            transactionTypes.append(type)
            AnalyticsManager.shared.log(
                TransactionTypeFilterAdded(
                    fromScreen: fromScreen,
                    transactionType: type.rawValue
                )
            )
        }
    }
}


