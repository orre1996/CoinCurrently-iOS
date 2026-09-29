//
//  CloseButton.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/15/26.
//

import SwiftUI

struct CloseButton: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }, label: {
            Image.cross
                .resizable()
                .foregroundStyle(Color.onSurfaceDimmer)
                .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                .padding(12)
        })
        .optionalGlassEffect(
            color: Color.surfaceContainerHigh,
            radius: 1000,
            isInteractive: true
        )
        .accessibilityLabel(Localization.string("Close sheet"))
    }
}
