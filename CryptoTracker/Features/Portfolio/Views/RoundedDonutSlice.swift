//
//  RoundedDonutSlice.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-07-28.
//

import SwiftUI

struct RoundedDonutSlice: Shape {
    var outerStartAngle: Double
    var outerEndAngle: Double
    var innerStartAngle: Double
    var innerEndAngle: Double
    var innerRadiusRatio: CGFloat = 0.55
    var innerCornerRadius: CGFloat = 8
    var outerCornerRadius: CGFloat = 6
    var outerRadiusScale: CGFloat = 1
    var explosionOffset: CGFloat = 0

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(outerRadiusScale, explosionOffset) }
        set {
            outerRadiusScale = newValue.first
            explosionOffset = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        guard outerEndAngle > outerStartAngle, innerEndAngle > innerStartAngle else { return Path() }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2
        let outerRadius = maxRadius * outerRadiusScale
        let innerRadius = outerRadius * innerRadiusRatio
        let ringThickness = outerRadius - innerRadius

        let innerCornerR = min(innerCornerRadius, ringThickness * 0.35)
        let outerCornerR = min(outerCornerRadius, ringThickness * 0.15)

        let midAngle = (outerStartAngle + outerEndAngle + innerStartAngle + innerEndAngle) / 4
        let midAngleRadians = Angle(degrees: midAngle).radians
        let offsetCenter = CGPoint(
            x: center.x + CGFloat(cos(midAngleRadians)) * explosionOffset,
            y: center.y + CGFloat(sin(midAngleRadians)) * explosionOffset
        )

        let outerTrim = trimAngle(for: outerCornerR, on: outerRadius)
        let innerTrim = trimAngle(for: innerCornerR, on: innerRadius)

        let outerArcStart = outerStartAngle + outerTrim
        let outerArcEnd = outerEndAngle - outerTrim
        let innerArcEndSide = innerEndAngle - innerTrim
        let innerArcStartSide = innerStartAngle + innerTrim

        guard outerArcEnd > outerArcStart, innerArcEndSide > innerArcStartSide else {
            return simpleSlicePath(center: offsetCenter, innerRadius: innerRadius, outerRadius: outerRadius)
        }

        var path = Path()
        path.move(to: polarPoint(center: offsetCenter, radius: outerRadius, degrees: outerArcStart))

        path.addArc(
            center: offsetCenter,
            radius: outerRadius,
            startAngle: .degrees(outerArcStart),
            endAngle: .degrees(outerArcEnd),
            clockwise: false
        )

        path.addQuadCurve(
            to: edgePoint(
                center: offsetCenter,
                outerRadius: outerRadius,
                innerRadius: innerRadius,
                outerDegrees: outerEndAngle,
                innerDegrees: innerEndAngle,
                inset: outerCornerR,
                fromOuterEdge: true
            ),
            control: polarPoint(center: offsetCenter, radius: outerRadius, degrees: outerEndAngle)
        )

        path.addLine(
            to: edgePoint(
                center: offsetCenter,
                outerRadius: outerRadius,
                innerRadius: innerRadius,
                outerDegrees: outerEndAngle,
                innerDegrees: innerEndAngle,
                inset: innerCornerR,
                fromOuterEdge: false
            )
        )

        path.addQuadCurve(
            to: polarPoint(center: offsetCenter, radius: innerRadius, degrees: innerArcEndSide),
            control: polarPoint(center: offsetCenter, radius: innerRadius, degrees: innerEndAngle)
        )

        path.addArc(
            center: offsetCenter,
            radius: innerRadius,
            startAngle: .degrees(innerArcEndSide),
            endAngle: .degrees(innerArcStartSide),
            clockwise: true
        )

        path.addQuadCurve(
            to: edgePoint(
                center: offsetCenter,
                outerRadius: outerRadius,
                innerRadius: innerRadius,
                outerDegrees: outerStartAngle,
                innerDegrees: innerStartAngle,
                inset: innerCornerR,
                fromOuterEdge: false
            ),
            control: polarPoint(center: offsetCenter, radius: innerRadius, degrees: innerStartAngle)
        )

        path.addLine(
            to: edgePoint(
                center: offsetCenter,
                outerRadius: outerRadius,
                innerRadius: innerRadius,
                outerDegrees: outerStartAngle,
                innerDegrees: innerStartAngle,
                inset: outerCornerR,
                fromOuterEdge: true
            )
        )

        path.addQuadCurve(
            to: polarPoint(center: offsetCenter, radius: outerRadius, degrees: outerArcStart),
            control: polarPoint(center: offsetCenter, radius: outerRadius, degrees: outerStartAngle)
        )

        path.closeSubpath()
        return path
    }

    private func trimAngle(for cornerRadius: CGFloat, on radius: CGFloat) -> Double {
        Double(asin(min(cornerRadius / radius, 1))) * 180 / .pi
    }

    private func polarPoint(center: CGPoint, radius: CGFloat, degrees: Double) -> CGPoint {
        let radians = degrees * .pi / 180
        return CGPoint(
            x: center.x + radius * CGFloat(cos(radians)),
            y: center.y + radius * CGFloat(sin(radians))
        )
    }

    private func edgePoint(
        center: CGPoint,
        outerRadius: CGFloat,
        innerRadius: CGFloat,
        outerDegrees: Double,
        innerDegrees: Double,
        inset: CGFloat,
        fromOuterEdge: Bool
    ) -> CGPoint {
        let outer = polarPoint(center: center, radius: outerRadius, degrees: outerDegrees)
        let inner = polarPoint(center: center, radius: innerRadius, degrees: innerDegrees)
        let dx = inner.x - outer.x
        let dy = inner.y - outer.y
        let length = max(sqrt(dx * dx + dy * dy), 0.001)
        let ux = dx / length
        let uy = dy / length

        if fromOuterEdge {
            return CGPoint(x: outer.x + ux * inset, y: outer.y + uy * inset)
        }

        return CGPoint(x: inner.x - ux * inset, y: inner.y - uy * inset)
    }

    private func simpleSlicePath(center: CGPoint, innerRadius: CGFloat, outerRadius: CGFloat) -> Path {
        var path = Path()
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: .degrees(innerStartAngle),
            endAngle: .degrees(innerEndAngle),
            clockwise: false
        )
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: .degrees(outerEndAngle),
            endAngle: .degrees(outerStartAngle),
            clockwise: true
        )
        path.closeSubpath()
        return path
    }
}
