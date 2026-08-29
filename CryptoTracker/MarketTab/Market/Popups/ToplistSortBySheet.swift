//
//  SelectDateSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/13/26.
//

import SwiftUI

struct ToplistSortBySheet: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category

    @ScaledMetric private var scale: CGFloat = 1

    let options: [SortOption]
    let selectedSortOption: SortOption
    let newOptionSelected: (SortOption) -> Void

    @State private var contentHeight: CGFloat = 0
    @State private var headerHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: "Sort By")
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
            ForEach(options, id: \.self) { option in
                SingleSelectView(
                    title: option.title,
                    accessibilityTitle: option.accessibilityTitle,
                    subtitle: option.subtitle,
                    imageCase: .nothing,
                    isSelected: option == selectedSortOption,
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


