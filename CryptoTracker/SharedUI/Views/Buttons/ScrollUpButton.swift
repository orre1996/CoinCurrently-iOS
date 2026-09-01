//
//  ScrollUpButton.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 3/2/26.
//

import SwiftUI

struct ScrollUpButton: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    let action: () -> Void
    let isVisible: Bool

    var body: some View {
        Button(action: action, label: {
            Image.arrowUp
                .resizable()
                .foregroundStyle(Color.onSurface)
                .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                .padding(16)
        })
        .optionalGlassEffect(
            color: Color.surfaceContainerHighest,
            radius: 1000,
            isInteractive: true
        )
        .padding(16)
        .opacity(isVisible ? 1 : 0)
        .animation(.default, value: isVisible)
        .allowsHitTesting(isVisible)
    }
}
