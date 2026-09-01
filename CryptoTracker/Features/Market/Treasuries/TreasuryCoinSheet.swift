//
//  TreasuryCoinSheet.swift
//  CoinCurrently
//

import SwiftUI

struct TreasuryCoinSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets

    let coins: [Toplist]
    let selectedCoinId: String
    let newCoinSelected: (Toplist) -> Void

    @State private var contentHeight: CGFloat = 0
    @State private var headerHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: "Select Coin")
                .readSize {
                    headerHeight = $0.height
                }

            Separator()
                .padding(.horizontal, 16)

            ScrollView(.vertical) {
                bodyView
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .presentationDetents([.height(max(1, contentHeight + headerHeight - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }

    private var bodyView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(coins, id: \.self) { coin in
                SingleSelectView(
                    title: coin.name ?? "",
                    accessibilityTitle: coin.name,
                    subtitle: coin.symbol?.uppercased(),
                    imageCase: .image(coin.image),
                    isSelected: coin.id == selectedCoinId,
                    didSelectOption: {
                        newCoinSelected(coin)
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
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
}
