//
//  SecondarButton.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/15/25.
//

import SwiftUI

struct TertiaryButton: View {
    let text: String
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var fullWidth: Bool = false
    var extraBig: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .padding(EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24))
                .font(extraBig ? .satoshiBold(16) : .satoshiMedium(16))
                .if(fullWidth) { view in
                    view.frame(maxWidth: .infinity)
                }
                .opacity(isLoading ? 0 : 1)
                .optionalGlassEffect(
                    color: Color.inverseSurface.opacity(isEnabled ? 1 : 0.4),
                    radius: 1000,
                    isInteractive: true
                )
                .foregroundStyle(Color.inverseOnContainer)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(isLoading)
                .overlay(
                    ActivityIndicator(size: 24, color: .inverseOnContainer)
                        .opacity(isLoading ? 1 : 0)
                        .accessibilityHidden(!isLoading)
                        .accessibilityLabel("Loading")
                )
        }
        .lineLimit(2)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .disabled(!isEnabled || isLoading)
    }
}
