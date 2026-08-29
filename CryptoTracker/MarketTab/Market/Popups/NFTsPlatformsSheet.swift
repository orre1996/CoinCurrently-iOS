//
//  SelectDateSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/13/26.
//

import SwiftUI

struct NFTsPlatformsSheet: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category

    @ScaledMetric private var scale: CGFloat = 1

    let allPlatforms: [NFTPlatform]
    let selectedPlatform: NFTPlatform
    let newPlatformSelected: (NFTPlatform) -> Void
    
    @State private var contentHeight: CGFloat = 0
    @State private var headerHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: "Filter By Chain")
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
            ForEach(allPlatforms, id: \.self) { platform in
                SingleSelectView(
                    title: platform.name ?? "",
                    accessibilityTitle: platform.accessibilityTitle,
                    subtitle: nil,
                    imageCase: platform.image == nil ? .nothing : .image(platform.image?.small),
                    isSelected: platform == selectedPlatform,
                    didSelectOption: {
                        newPlatformSelected(platform)
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


