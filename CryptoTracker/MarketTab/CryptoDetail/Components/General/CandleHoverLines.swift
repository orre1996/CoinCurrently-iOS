//
//  CandleHoverLines.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-09-10.
//

import SwiftUI

struct CandleHoverLines: View {
    let chartSize: CGSize
    let xPosition: CGFloat
    let yPosition: CGFloat
    let isDragging: Bool
    let topPadding: CGFloat

    var body: some View {
        ZStack {
            HorizontalHoverLine()
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .frame(width: chartSize.width - 0.5, height: 1)
                .position(x: chartSize.width / 2, y: yPosition)
                .padding(.top, topPadding)
            
            VerticalHoverLine()
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .frame(width: 1, height: topPadding + chartSize.height)
                .position(x: xPosition, y: (topPadding / 2) + (chartSize.height / 2))
        }
        .foregroundStyle(Color.outline.opacity(0.5))
        .opacity(isDragging ? 1 : 0)
        .animation(.default, value: isDragging)
    }
}
