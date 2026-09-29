//
//  TreasuryEntityFilterSheet.swift
//  CoinCurrently
//

import SwiftUI

struct TreasuryEntityFilterSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets

    let selectedFilter: TreasuryEntityFilter
    let newFilterSelected: (TreasuryEntityFilter) -> Void

    @State private var contentHeight: CGFloat = 0
    @State private var headerHeight: CGFloat = 0

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
        }
        .presentationDetents([.height(max(1, contentHeight + headerHeight - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }

    private var bodyView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(TreasuryEntityFilter.allCases, id: \.self) { filter in
                SingleSelectView(
                    title: Localization.string(filter.title),
                    accessibilityTitle: Localization.string(filter.accessibilityTitle),
                    subtitle: nil,
                    imageCase: .nothing,
                    isSelected: filter == selectedFilter,
                    didSelectOption: {
                        newFilterSelected(filter)
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
