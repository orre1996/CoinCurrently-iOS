//
//  PrimaryButton.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-20.
//

import SwiftUI

struct PrimaryButton: View {
    let text: String
    var accessibilityLabel: String? = nil
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var fullWidth: Bool = false
    var opaqueBackground: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .padding(EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24))
                .font(.satoshiBold(18))
                .if(fullWidth) { view in
                    view.frame(maxWidth: .infinity)
                }
                .opacity(isLoading ? 0 : 1)
                .optionalGlassEffect(
                    color: Color.primary.opacity(isEnabled ? 1 : 0.4),
                    radius: 1000,
                    isInteractive: true,
                    forceOpaque: opaqueBackground
                )
                .foregroundStyle(Color.onPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(isLoading)
                .overlay(
                    ActivityIndicator(size: 24, color: .onPrimary)
                        .opacity(isLoading ? 1 : 0)
                        .accessibilityHidden(!isLoading)
                        .accessibilityLabel(Localization.string("Loading"))
                )
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .lineLimit(2)
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(accessibilityLabel ?? text)
    }
}
