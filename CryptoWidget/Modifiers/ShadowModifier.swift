//
//  ShadowModifier.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-02-01.
//

import Foundation
import SwiftUI

struct CardBackground: ViewModifier {
    var hasPadding: Bool = true
    var padding: CGFloat = 16
    var backgroundColor = Color.surfaceContainerLow
    var cornerRadius: CGFloat = 12
    var outlineColor: Color = Color.clear
    
    func body(content: Content) -> some View {
        content
            .padding(hasPadding ? padding : 0)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(outlineColor, lineWidth: 2)
            )
            .animation(.none, value: UUID())

    }
}

extension View {
    func cardBackground(
        hasPadding: Bool = true,
        padding: CGFloat = 16,
        backgroundColor: Color = Color.surfaceContainerLow,
        cornerRadius: CGFloat = 12,
        outlineColor: Color = Color.clear
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: CardBackground(
                hasPadding: hasPadding,
                padding: padding,
                backgroundColor: backgroundColor,
                cornerRadius: cornerRadius,
                outlineColor: outlineColor
            )
        )
    }
}

