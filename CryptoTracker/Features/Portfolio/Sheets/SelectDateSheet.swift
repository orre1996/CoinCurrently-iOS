//
//  SelectDateSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/13/26.
//

import SwiftUI

struct SelectDateSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let fromScreen: ScreenLabel
    @Binding var selectedOption: DateOption
    let selectCustomDate: () -> Void
    
    @State private var contentHeight: CGFloat = 0
    @State private var headerHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: Localization.string("Filter By Date"))
                .readSize {
                    headerHeight = $0.height
                }
            
            Separator()
                .padding(.horizontal, 16)
            
            ScrollView(.vertical) {
                VStack(spacing: 4) {
                    ForEach(DateOption.allCases, id: \.self) { option in
                        SingleSelectView(
                            title: Localization.string(option.title),
                            accessibilityTitle: {
                                if case .custom = option {
                                    return Localization.string("Custom. Select a custom date range")
                                }
                                return nil
                            }(),
                            subtitle: nil,
                            imageCase: .nothing,
                            isSelected: option.type == selectedOption.type,
                            canNavigate: {
                                if case .custom = option { return true }
                                return false
                            }(),
                            didSelectOption: {
                                AnalyticsManager.shared.log(
                                    DateFilterOptionSelected(
                                        fromScreen: fromScreen,
                                        option: option.title
                                    )
                                )
                                if case .custom = option {
                                    selectCustomDate()
                                } else {
                                    selectedOption = option
                                }
                                
                                presentationMode.wrappedValue.dismiss()
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
        }
        .presentationDetents([.height(max(1, contentHeight + headerHeight + 24 - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }
}
