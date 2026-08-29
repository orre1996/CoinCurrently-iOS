//
//  BorderModifier.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-16.
//

import SwiftUI

struct BorderModifier: ViewModifier {
    
    var color: [Color] = [Color.outlineVariant, Color.outlineVariant.opacity(0)]
    var cornerRadius: CGFloat = 8
    var showLine: Bool = true
    var withPadding: Bool = true
    var lineWidth: CGFloat = 2
    
    func body(content: Content) -> some View {
        content
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(LinearGradient(colors: color, startPoint: .top, endPoint: .bottom), lineWidth: showLine ? lineWidth : 0)
                    .padding(withPadding ? 0.5 : 0)
            )
    }
}

extension View {
    func capsuleBorderModifier() -> some View {
        ModifiedContent(
            content: self,
            modifier: BorderModifier(
                color: [Color.outlineVariant],
                cornerRadius: 1000
            )
        )
    }
    
    func roundedBorderModifier(
        radius: CGFloat = 8,
        outlineColor: [Color] = [Color.outlineVariant]
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: BorderModifier(
                color: outlineColor,
                cornerRadius: radius,
                lineWidth: 1
            )
        )
    }
}

