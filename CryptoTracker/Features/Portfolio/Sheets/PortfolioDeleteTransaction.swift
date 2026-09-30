//
//  PortfolioDeleteTransaction.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-01-23.
//

import SwiftUI

struct PortfolioDeleteTransaction: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @AccessibilityFocusState private var focusHeader
    
    let close: (Bool) -> Void
    
    var body: some View {
        ZStack {
            Color.overlayBackground.opacity(0.7)
                .ignoresSafeArea()
                .highPriorityGesture(DragGesture())
                .onTapGesture {
                    close(false)
                }
            
            VStack(spacing: 0) {
                headerView
                
                actionButtons
            }
            .padding(16)
            .background(Color.surfaceContainerLow)
            .cornerRadius(8)
            .multilineTextAlignment(.center)
            .foregroundColor(.onSurface)
            .frame(minWidth: 0, maxWidth: verticalSizeClass == .compact ? 500 : 340, alignment: .center)
            .padding(.horizontal, 16)
        }
        .onUIKitDidAppear {
            focusHeader = true
        }
    }
    
    private var headerView: some View {
        Text(Localization.string("Are you sure you want to delete this transaction?"))
            .foregroundColor(.onSurface)
            .font(.poppinsRegular(14))
            .multilineTextAlignment(.center)
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            .accessibilityFocused($focusHeader)
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact

        AdaptiveStack(isHorizontal: isHorizontal, spacing: 16) {
            PrimaryButton(text: Localization.string("No"), action: {
                close(false)
            })
            .accessibilityLabel(Localization.string("No, close window"))
            
            PrimaryButton(text: Localization.string("Yes"), action: {
                close(true)
            })
            .accessibilityLabel(Localization.string("Yes, close window"))
        }
        .padding(.top, 16)
    }
}
