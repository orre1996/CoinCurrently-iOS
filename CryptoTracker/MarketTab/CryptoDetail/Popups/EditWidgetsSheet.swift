//
//  EditWidgetsSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/26/25.
//

import SwiftUI

struct EditWidgetsSheet: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var buttonsHeight: CGFloat = 0
    
    let widgetCoins: [Toplist]
    let currentCoinName: String
    var replaceCoin: (Toplist) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(
                title: "Replace Coin",
                bottomPadding: 16
            )
            .readSize {
                headerHeight = $0.height
            }
            
            bodyView
            
            Separator()
                .padding(.horizontal, 16)

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 4) {
                    widgetsView
                }
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
            .scrollBounceBehavior(.basedOnSize)
            
            Separator()
                .padding(
                    EdgeInsets(
                        top: 0,
                        leading: 16,
                        bottom: 0,
                        trailing: 16
                    )
                )
            
            actionButtons
                .readSize {
                    buttonsHeight = $0.height
                }
        }
        .presentationDetents([.height(max(1, headerHeight + contentHeight + buttonsHeight + 40 - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private var bodyView: some View {
        Text("Your widgets list is full (8/8).\nChoose a coin in your widgets to replace with \(currentCoinName).")
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(Color.onSurfaceDim)
            .font(.satoshiRegular(16))
            .lineSpacing(4)
            .padding(
                EdgeInsets(
                    top: 0,
                    leading: 16,
                    bottom: 24,
                    trailing: 16
                )
            )
            .accessibilityLabel("Your widgets list is full (8 of 8). Choose a coin in your widgets to replace with \(currentCoinName).")
    }
    
    @ViewBuilder
    private var widgetsView: some View {
        ForEach(Array(widgetCoins.enumerated()), id: \.element) { index, coin in
            SelectCoinView(
                toplist: coin,
                isSelectable: true,
                isSelected: false,
                itemType: "Coin",
                index: index,
                totalCount: widgetCoins.count,
                onClick: {
                    replaceCoin(coin)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 8) {
            SecondaryButton(
                text: "Close",
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
}
