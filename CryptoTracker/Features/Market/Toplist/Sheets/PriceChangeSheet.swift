//
//  SelectDateSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/13/26.
//

import SwiftUI

struct PriceChangeSheet: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category

    @ScaledMetric private var scale: CGFloat = 1

    var options: [PriceChange] = PriceChange.allCases
    let selectedPriceChangeOption: PriceChange
    let newOptionSelected: (PriceChange) -> Void
    
    @State private var contentHeight: CGFloat = 0
    @State private var headerHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: Localization.string("Price Change"))
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
        .presentationDetents([.height(max(1, contentHeight + headerHeight + 24 - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }

    private var bodyView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(options, id: \.self) { option in
                SingleSelectView(
                    title: Localization.string(option.rawValue),
                    accessibilityTitle: Localization.string(option.accessibilityTimeframe),
                    subtitle: Localization.string(option.subtitle),
                    imageCase: .nothing,
                    isSelected: option == selectedPriceChangeOption,
                    didSelectOption: {
                        newOptionSelected(option)
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


