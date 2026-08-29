//
//  ChartHoverView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-08-06.
//

import SwiftUI

struct VerticalHoverLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        return path
    }
}

struct HorizontalHoverLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

struct ChartHoverView: View {
    let positions: [CGPoint]
    let size: CGSize
    let color: Color?
    var topPadding: CGFloat = 0
    
    // Temp
    var extraSize: Bool = false
    
    var body: some View {
        let color = color ?? Color.onSurfaceDim
        
        ForEach(0..<positions.count, id: \.self) { index in
            let position = positions[index]

            ZStack {
                VerticalHoverLine()
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(Color.outline.opacity(0.5))
                    .frame(width: 2)
                    .position(x: position.x + 1.25, y: (size.height / 2))
                
                Circle()
                    .fill(color.opacity(0.25))
                    .frame(width: 20, height: 20, alignment: .center)
                    .overlay(
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6, alignment: .center)
                            .zIndex(2)
                    )
                    .position(x: position.x + 0.25, y: position.y)
                    .padding(.vertical, topPadding)
            }
        }
        .animation(.none, value: positions)
        .accessibilityHidden(true)
    }
}
