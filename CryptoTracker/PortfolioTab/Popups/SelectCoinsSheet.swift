//
//  SelectDateSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/13/26.
//

import SwiftUI

struct SelectCoinsSheet: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1

    let fromScreen: ScreenLabel
    let coins: [Toplist]
    @Binding var selectedCoins: [Toplist]
    
    @State private var contentHeight: CGFloat = 0
    @State private var headerHeight: CGFloat = 0
    @State private var buttonsHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: "Filter By Coins")
                .readSize {
                    headerHeight = $0.height
                }
            
            Separator()
                .padding(.horizontal, 16)
            
            ScrollView(.vertical) {
                LazyVStack(spacing: 4) {
                    ForEach(coins, id: \.self) { coin in
                        coinOptionRow(
                            coin: coin,
                            isSelected: selectedCoins.contains(where: { $0.id == coin.id }),
                            didSelectOption: {
                                toggleCoin(coin)
                            }
                        )
                    }
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
                .padding(.horizontal, 16)
            
            actionButtons
                .readSize {
                    buttonsHeight = $0.height
                }
        }
        .ignoresSafeArea(edges: .bottom)
        .presentationBackground(Color.surfaceContainerLow)
        .presentationDetents([.height(max(1, contentHeight + headerHeight + buttonsHeight - safeAreaInsets.resolvedBottom))])
    }

    private func coinOptionRow(
        coin: Toplist,
        isSelected: Bool,
        didSelectOption: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            ShimmeringImage(
                imageUrl: coin.image,
                downloading: false,
                size: 32 * min(scale, 1.5)
            )
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(coin.symbol?.uppercased() ?? "")
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(16))
                
                Text(coin.name ?? "")
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .font(.satoshiBold(12))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            CheckboxView(isChecked: .constant(isSelected))
                .disabled(true)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(coinAccessibilityLabel(coin))
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onTapGesture {
            didSelectOption()
        }
    }
    
    private func coinAccessibilityLabel(_ coin: Toplist) -> String {
        let name = coin.name ?? ""
        let symbol = coin.symbol?.uppercased() ?? ""
        
        if !name.isEmpty, !symbol.isEmpty {
            return "\(name). \(symbol)"
        }
        
        return name.isEmpty ? symbol : name
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact

        AdaptiveStack(isHorizontal: isHorizontal, spacing: 12) {
            SecondaryButton(
                text: "Clear",
                accessibilityLabel: "Clear filters",
                fullWidth: true,
                opaqueBackground: true,
                action: {
                    if !selectedCoins.isEmpty {
                        AnalyticsManager.shared.log(
                            CoinFilterCleared(fromScreen: fromScreen)
                        )
                    }
                    selectedCoins.removeAll()
                }
            )
            
            PrimaryButton(
                text: "Apply",
                accessibilityLabel: "Apply filters",
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
                bottom: 16,
                trailing: 16
            )
        )
    }
    
    private func toggleCoin(_ coin: Toplist) {
        if selectedCoins.contains(where: { $0.id == coin.id }) {
            selectedCoins.removeAll(where: { $0.id == coin.id })
            AnalyticsManager.shared.log(
                CoinFilterRemoved(
                    fromScreen: fromScreen,
                    coinName: coin.name ?? ""
                )
            )
        } else {
            selectedCoins.append(coin)
            AnalyticsManager.shared.log(
                CoinFilterAdded(
                    fromScreen: fromScreen,
                    coinName: coin.name ?? ""
                )
            )
        }
    }
}
