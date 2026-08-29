//
//  CompareChartHoverView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-08-12.
//

import SwiftUI

struct CompareChartHoverView: View {
    let mainDragPosition: CGPoint
    let hideMainMark: Bool
    
    let compareDragPosition: CGPoint
    let hideCompareMark: Bool
    
    let size: CGSize
    let topPadding: CGFloat

    var body: some View {
        ZStack {
            VerticalHoverLine()
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundStyle(Color.outline.opacity(0.5))
                .frame(width: 2)
                .position(x: mainDragPosition.x, y: size.height / 2)
            
            if !hideMainMark {
                Circle()
                    .fill(Color.primary50.opacity(0.25))
                    .frame(width: 24, height: 24, alignment: .center)
                    .overlay(
                        Circle()
                            .fill(Color.primary50)
                            .frame(width: 6, height: 6, alignment: .center)
                            .zIndex(2)
                    )
                    .position(x: mainDragPosition.x, y: mainDragPosition.y)
                    .padding(.top, topPadding)
            }

            if !hideCompareMark {
                Circle()
                    .fill(Color.blue50.opacity(0.25))
                    .frame(width: 24, height: 24, alignment: .center)
                    .overlay(
                        Circle()
                            .fill(Color.blue50)
                            .frame(width: 6, height: 6, alignment: .center)
                            .zIndex(2)
                    )
                    .position(x: mainDragPosition.x, y: compareDragPosition.y)
                    .padding(.top, topPadding)
            }
        }
        .animation(.none, value: mainDragPosition)
        .animation(.none, value: compareDragPosition)
    }
}
