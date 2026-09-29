//
//  SelectTransactionTypeSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/25/25.
//

import SwiftUI

struct SelectTransactionTypeSheet: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    @State var headerHeight: CGFloat = 0
    @State var contentHeight: CGFloat = 0
    
    let transactionSelected: (PortfolioTransactionType) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: Localization.string("Select Transaction Type"))
                .readSize {
                    headerHeight = $0.height
                }
            
            Separator()
                .padding(.horizontal, 16)
            
            ScrollView(.vertical) {
                bodyView
                    .padding(.horizontal, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .presentationDetents([.height(max(1, headerHeight + contentHeight + 16 - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private var bodyView: some View {
        VStack(alignment: .leading, spacing: 4) {
            TransactionTypeView(
                title: Localization.string("Buy"),
                subtitle: Localization.string("Bought coins with cash."),
                image: .plus,
                isMultiSelectEnabled: false,
                isSelected: false,
                viewTapped: {
                    transactionSelected(.buy)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            
            TransactionTypeView(
                title: Localization.string("Sell"),
                subtitle: Localization.string("Sold coins with cash."),
                image: .minus,
                isMultiSelectEnabled: false,
                isSelected: false,
                viewTapped: {
                    transactionSelected(.sell)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            
            TransactionTypeView(
                title: Localization.string("Swap"),
                subtitle: Localization.string("Swapped one coin for another."),
                image: .trade,
                isMultiSelectEnabled: false,
                isSelected: false,
                viewTapped: {
                    transactionSelected(.swap)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            
            TransactionTypeView(
                title: Localization.string("Deposit"),
                subtitle: Localization.string("Deposited coins into your wallet."),
                image: .deposit,
                isMultiSelectEnabled: false,
                isSelected: false,
                viewTapped: {
                    transactionSelected(.transferIn)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            
            TransactionTypeView(
                title: Localization.string("Withdraw"),
                subtitle: Localization.string("Withdrawn coins out of your wallet."),
                image: .withdraw,
                isMultiSelectEnabled: false,
                isSelected: false,
                viewTapped: {
                    transactionSelected(.transferOut)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 24)
        .readSize {
            contentHeight = $0.height
        }
    }
}
