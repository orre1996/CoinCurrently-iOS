//
//  FearGreedMeter.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/7/25.
//

import SwiftUI

struct FearGreedMeter: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let height: CGFloat
    
    var body: some View {
        HStack(spacing: 0) {
            #if IS_WIDGET
            Color.extremeFear(for: colorScheme)
            Color.fear(for: colorScheme)
            Color.neutral(for: colorScheme)
            Color.greed(for: colorScheme)
            Color.extremeGreed(for: colorScheme)
            #else
            Color.extremeFear
            Color.fear
            Color.neutral
            Color.greed
            Color.extremeGreed
            #endif
        }
        .frame(height: height)
        .clipShape(Capsule())
    }
    
    static func indicatorSize(circleSize: CGFloat, outlinePadding: CGFloat) -> CGFloat {
        circleSize + (outlinePadding * 2)
    }
    
    static func indicatorOffset(
        containerWidth: CGFloat,
        indicatorSize: CGFloat,
        percent: CGFloat,
        horizontalPadding: CGFloat = 0
    ) -> CGFloat {
        let trackWidth = containerWidth - (horizontalPadding * 2)
        return horizontalPadding + ((trackWidth - indicatorSize) * percent)
    }
}
