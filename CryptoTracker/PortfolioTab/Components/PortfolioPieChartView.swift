//
//  PortfolioPieChartView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-07-28.
//

import SwiftUI

struct PortfolioPieChartView: View {
    let slices: [PortfolioPieSlice]
    @Binding var selectedSliceId: String?
    var isLoading: Bool = false
    var hideData: Bool = false

    private let innerRadiusRatio = PortfolioPieChartLayout.innerRadiusRatio
    private let selectedOuterRadiusScale: CGFloat = 1.1
    private let selectedExplosionOffset: CGFloat = 4
    private let selectionAnimation: Animation = .spring(response: 0.35, dampingFraction: 0.72)

    var body: some View {
        GeometryReader { reader in
            let size = min(reader.size.width, reader.size.height)
            let chartSize = CGSize(width: size, height: size)

            ZStack {
                if slices.isEmpty {
                    emptyChart(in: chartSize)
                } else {
                    chartContent(size: chartSize)
                }
            }
            .frame(width: reader.size.width, height: reader.size.height)
        }
    }

    private func isFullCircleSlice(_ slice: PortfolioPieSlice) -> Bool {
        slice.outerEndAngle - slice.outerStartAngle >= 359.5
    }

    @ViewBuilder
    private func chartContent(size: CGSize) -> some View {
        ZStack {
            ForEach(slices) { slice in
                let isSelected = selectedSliceId == slice.id
                let displayColor: Color = {
                    if slice.symbol == "OTHER" {
                        return Color.primary20
                    }
                    if let hex = slice.color {
                        return Color(hex: hex)
                    }
                    return Color.surfaceContainerLow
                }()

                if isFullCircleSlice(slice) {
                    FullDonutShape(
                        innerRadiusRatio: innerRadiusRatio,
                        outerRadiusScale: isSelected ? selectedOuterRadiusScale : 1
                    )
                    .fill(displayColor, style: FillStyle(eoFill: true))
                    .frame(width: size.width, height: size.height)

                    if isLoading {
                        FullDonutShape(innerRadiusRatio: innerRadiusRatio)
                            .fill(Color.onSurface.opacity(0.25), style: FillStyle(eoFill: true))
                            .frame(width: size.width, height: size.height)
                            .shimmer()
                    }
                } else {
                    RoundedDonutSlice(
                        outerStartAngle: slice.outerStartAngle,
                        outerEndAngle: slice.outerEndAngle,
                        innerStartAngle: slice.innerStartAngle,
                        innerEndAngle: slice.innerEndAngle,
                        innerRadiusRatio: innerRadiusRatio,
                        outerRadiusScale: isSelected ? selectedOuterRadiusScale : 1,
                        explosionOffset: isSelected ? selectedExplosionOffset : 0
                    )
                    .fill(displayColor)
                    .frame(width: size.width, height: size.height)

                    if isLoading {
                        RoundedDonutSlice(
                            outerStartAngle: slice.outerStartAngle,
                            outerEndAngle: slice.outerEndAngle,
                            innerStartAngle: slice.innerStartAngle,
                            innerEndAngle: slice.innerEndAngle,
                            innerRadiusRatio: innerRadiusRatio
                        )
                        .fill(Color.onSurface.opacity(0.25))
                        .frame(width: size.width, height: size.height)
                        .shimmer()
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel(for: slices.first { $0.id == selectedSliceId }))

            centerLabel
        }
        .animation(selectionAnimation, value: selectedSliceId)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    handleTap(at: value.location, in: size)
                }
        )
    }

    @ViewBuilder
    private var centerLabel: some View {
        if let selected = slices.first(where: { $0.id == selectedSliceId }) {
            VStack(spacing: 0) {
                Text(selected.symbol)
                    .font(.satoshiBold(18))
                    .foregroundStyle(Color.onSurfaceDim)

                Text(formattedPercent(selected.percentage))
                    .font(.satoshiBold(22))
                    .foregroundStyle(Color.onSurface)
            }
            .animation(selectionAnimation, value: selectedSliceId)
        }
    }

    @ViewBuilder
    private func emptyChart(in size: CGSize) -> some View {
        FullDonutShape(innerRadiusRatio: innerRadiusRatio)
            .fill(Color.onSurfaceDimmer, style: FillStyle(eoFill: true))
            .frame(width: size.width, height: size.height)
            .accessibilityLabel("Empty portfolio allocation chart")
    }

    private func handleTap(at location: CGPoint, in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        let outerRadius = size.width / 2
        let innerRadius = outerRadius * innerRadiusRatio

        guard distance >= innerRadius, distance <= outerRadius * selectedOuterRadiusScale else {
            withAnimation(selectionAnimation) {
                selectedSliceId = nil
            }
            return
        }

        let tapAngle = normalizeAngle(atan2(dy, dx) * 180 / .pi)

        if let tappedSlice = slices.first(where: { slice in
            sliceContains(angle: tapAngle, distance: distance, slice: slice, outerRadius: outerRadius, innerRadius: innerRadius)
        }) {
            withAnimation(selectionAnimation) {
                selectedSliceId = selectedSliceId == tappedSlice.id ? nil : tappedSlice.id
            }
        } else {
            withAnimation(selectionAnimation) {
                selectedSliceId = nil
            }
        }
    }

    private func normalizeAngle(_ angle: Double) -> Double {
        var result = angle
        while result < 0 { result += 360 }
        while result >= 360 { result -= 360 }
        return result
    }

    private func sliceContains(
        angle: Double,
        distance: CGFloat,
        slice: PortfolioPieSlice,
        outerRadius: CGFloat,
        innerRadius: CGFloat
    ) -> Bool {
        if isFullCircleSlice(slice) {
            return true
        }

        let ringThickness = max(outerRadius - innerRadius, 1)
        let t = Double((distance - innerRadius) / ringThickness)
        let start = lerpAngle(slice.outerStartAngle, slice.innerStartAngle, t)
        let end = lerpAngle(slice.outerEndAngle, slice.innerEndAngle, t)
        return containsAngle(angle, start: start, end: end)
    }

    private func lerpAngle(_ outer: Double, _ inner: Double, _ t: Double) -> Double {
        outer + (inner - outer) * t
    }

    private func containsAngle(_ angle: Double, start: Double, end: Double) -> Bool {
        if end - start >= 359.5 {
            return true
        }

        let normalized = normalizeAngle(angle)
        let normalizedStart = normalizeAngle(start)
        let normalizedEnd = normalizeAngle(end)

        if normalizedStart <= normalizedEnd {
            return normalized >= normalizedStart && normalized <= normalizedEnd
        }

        return normalized >= normalizedStart || normalized <= normalizedEnd
    }

    private func formattedPercent(_ percentage: Double) -> String {
        let value = percentage * 100
        if value >= 99.995 {
            return value.formatted(.number.precision(.fractionLength(1))) + "%"
        }
        return value.formatted(.number.precision(.fractionLength(2))) + "%"
    }

    private func accessibilityLabel(for slice: PortfolioPieSlice?) -> String {
        guard let slice else {
            return "Portfolio allocation chart"
        }

        let percent = formattedPercent(slice.percentage)
        return "\(slice.symbol), \(percent) of portfolio"
    }
}

private struct FullDonutShape: Shape {
    var innerRadiusRatio: CGFloat
    var outerRadiusScale: CGFloat = 1

    var animatableData: CGFloat {
        get { outerRadiusScale }
        set { outerRadiusScale = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2 * outerRadiusScale
        let innerRadius = outerRadius * innerRadiusRatio

        var path = Path()
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: false
        )
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: .degrees(360),
            endAngle: .degrees(0),
            clockwise: false
        )
        return path
    }
}
