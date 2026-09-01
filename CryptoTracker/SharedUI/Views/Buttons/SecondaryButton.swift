//
//  SecondarButton.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/15/25.
//

import SwiftUI

struct SecondaryButton: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    let text: String
    var accessibilityLabel: String? = nil
    var icon: Image? = nil
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var fullWidth: Bool = false
    var minWidth: CGFloat? = nil
    var opaqueBackground: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 8) {
                if let icon {
                    icon
                        .resizable()
                        .frame(width: 20 * min(scale, 1.5), height: 20 * min(scale, 1.5))
                        .foregroundStyle(Color.onSurfaceDimmer)
                }
                
                Text(text)
                    .font(.satoshiBold(18))
                    .foregroundStyle(Color.onSurface)
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: icon == nil ? 16 : 24))
            .if(fullWidth) { view in
                view.frame(maxWidth: .infinity)
            }
            .if(minWidth != nil) { view in
                view.frame(minWidth: minWidth ?? 0)
            }
            .opacity(isLoading ? 0 : 1)
            .optionalGlassEffect(
                color: Color.surfaceContainerHigh,
                radius: 1000,
                isInteractive: true,
                forceOpaque: opaqueBackground
            )
            .opacity(isEnabled ? 1 : 0.4)
            .clipShape(Capsule())
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityHidden(isLoading)
            .overlay(
                ActivityIndicator(size: 24, color: .onSurface)
                    .opacity(isLoading ? 1 : 0)
                    .accessibilityHidden(!isLoading)
                    .accessibilityLabel("Loading")
            )
        }
        .lineLimit(2)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(accessibilityLabel ?? text)
    }
}
