//
//  FilterButtonView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/29/25.
//

import SwiftUI

struct FilterButtonView: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    let title: String
    var accessibilityLabel: String? = nil
    let isActive: Bool
    let action: () -> Void

    private var glassEffectColor: Color {
        if #available(iOS 27, *) {
            Color.surfaceContainerHigh
        } else {
            Color.clear
        }
    }
    
    var body: some View {
        Button(action: {
            action()
        }, label: {
            HStack(spacing: 8) {
                Text(title)
                    .font(.satoshiMedium(16))
                    .lineLimit(1)
                
                Image.chevronDown
                    .resizable()
                    .frame(width: 16 * min(scale, 1.5), height: 16 * min(scale, 1.5))
            }
            .padding(
                EdgeInsets(
                    top: 10,
                    leading: 12,
                    bottom: 10,
                    trailing: 16
                )
            )
            .capsuleBorderModifier()
            .optionalGlassEffect(
                color: glassEffectColor,
                radius: 1000,
                isInteractive: true
            )
            .whenBelowIOS26 { view in
                view.overlay(
                    RoundedRectangle(cornerRadius: 1000)
                        .stroke(Color.outlineVariant, lineWidth: 1)
                )
            }
        })
        .foregroundStyle(isActive ? Color.onSurface : Color.onSurfaceDim)
        .accessibilityLabel(accessibilityLabel ?? title)
    }
}
