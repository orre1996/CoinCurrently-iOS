//
//  FearGreedPaths.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-10.
//

import SwiftUI

struct FearGreedArrow: Shape {
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: CGPoint(x: 0, y: 0.4 * rect.height))
            
            path.addLine(to: CGPoint(x: 0.5 * rect.width, y: 0.1 * rect.height))
            
            path.addLine(to: CGPoint(x: 0.5 * rect.width, y: 0.9 * rect.height))
            
            path.addLine(to: CGPoint(x: 0, y: 0.6 * rect.height))
            
            path.closeSubpath()
        }
    }
}

struct RoundedTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: CGPoint(x: 0.5 * rect.width, y: 0))
            
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            
            path.closeSubpath()
            
        }
        .strokedPath(StrokeStyle(lineWidth: 12, lineJoin: .round))
    }
}

struct FearGreedArrowHomeView: Shape {
    func path(in rect: CGRect) -> Path {
        let cen =  CGPoint(x: rect.size.width / 2, y: rect.size.height / 2)
        let r0 = rect.size.height / 2 // Inner
        
        return Path { path in
            path.addArc(center: cen, radius: r0, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 360), clockwise: false)
            
            path.move(to: CGPoint(x: 0, y: 0.49 * rect.height))
            
            path.addLine(to: CGPoint(x: 0.5 * rect.width, y: 0.2 * rect.height))
            
            path.addLine(to: CGPoint(x: 0.5 * rect.width, y: 0.8 * rect.height))
            
            path.addLine(to: CGPoint(x: 0, y: 0.51   * rect.height))
            
            path.closeSubpath()
        }
    }
}

#if IS_APP
func getIndexColor(indexValue: String) -> Color {
    let intValue = Int(indexValue) ?? 0

    if (intValue < 20) { return .extremeFear }
    else if (intValue < 40)  { return .fear }
    else if (intValue < 60)  { return .neutral }
    else if (intValue < 80)  { return .greed }
    else { return .extremeGreed }
}
#elseif IS_WIDGET || IS_WATCH
func getIndexColor(
    indexValue: String,
    for scheme: ColorScheme
) -> Color {
    let intValue = Int(indexValue) ?? 0

    if (intValue < 20) { return .extremeFear(for: scheme) }
    else if (intValue < 40)  { return .fear(for: scheme) }
    else if (intValue < 60)  { return .neutral(for: scheme) }
    else if (intValue < 80)  { return .greed(for: scheme) }
    else { return .extremeGreed(for: scheme) }
}
#endif

func getIndexString(indexValue: String) -> String {
    let intValue = Int(indexValue) ?? 0

    if (intValue < 20) { return "Extreme Fear" }
    else if (intValue < 40)  { return "Fear" }
    else if (intValue < 60)  { return "Neutral" }
    else if (intValue < 80)  { return "Greed" }
    else { return "Extreme Greed" }
}
