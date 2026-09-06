//
//  PriceLineChartView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-08-03.
//

import SwiftUI

#if IS_APP || IS_WATCH
struct PriceLineChartView: View {
    let prices: [Double]
    let color: Color?
    var isGraphFilled = true
    var lineWidth: CGFloat = 1
    var dragPositions = [CGPoint]()
    var size: CGSize = .zero
    var isDragging: Bool = false
    var dropCount: Int = 0
    var isEmptyAtBottom = false
    var showLivePriceIndicator = false
    var dash: [CGFloat] = []
    var normalizationMin: Double? = nil
    var normalizationMax: Double? = nil

    #if DEBUG
    @State private var trimEnd: CGFloat = 1
    #else
    private let trimEnd: CGFloat = 1
    #endif

    private var realPrices: [Double] {
        guard !prices.isEmpty, let firstPrice = prices.first else { return [] }
        
        var allSame = true
        var minValue = normalizationMin ?? Double.infinity
        var maxValue = normalizationMax ?? -Double.infinity
        
        if normalizationMin == nil || normalizationMax == nil {
            for price in prices {
                if price != -1 {
                    if price < minValue { minValue = price }
                    if price > maxValue { maxValue = price }
                    if price != firstPrice {
                        allSame = false
                    }
                }
            }
        } else {
            for price in prices where price != -1 {
                if price != firstPrice {
                    allSame = false
                }
            }
        }
        
        if allSame && minValue != Double.infinity {
            return isEmptyAtBottom ? [0, 0] : [0.5, 0.5]
        }
        
        guard minValue != Double.infinity && maxValue != -Double.infinity else {
            return isEmptyAtBottom ? [0, 0] : [0.5, 0.5]
        }
        
        let range = maxValue - minValue
        if range == 0 {
            return isEmptyAtBottom ? [0, 0] : [0.5, 0.5]
        }
        
        let normalized = prices.map { price in
            price == -1 ? -1 : (price - minValue) / range
        }
        
        return Array(normalized.dropLast(dropCount))
    }

    private func lastPoint(in prices: [Double]) -> CGPoint? {
        guard prices.count > 1,
              let lastIndex = prices.lastIndex(where: { $0 != -1 }) else { return nil }
        let x = CGFloat(lastIndex) / CGFloat(prices.count - 1)
        let y = 1 - CGFloat(prices[lastIndex])
        return CGPoint(x: x, y: y)
    }

    var body: some View {
        let color = color ?? Color.onSurfaceDim
        let sizeWidth = max(1, size.width)
        let firstPosition = (dragPositions.first?.x ?? 0) / sizeWidth
        let lastPosition = (dragPositions.last?.x ?? 0) / sizeWidth
        
        let singleLineGradient = Gradient(stops: [
            Gradient.Stop(color: color, location: 0),
            Gradient.Stop(color: color, location: 1)
        ])
        
        let singleHoverLineGradient = Gradient(stops: [
            Gradient.Stop(color: color, location: -1),
            Gradient.Stop(color: color, location: min(max(firstPosition, 0), 1)),
            Gradient.Stop(color: color.opacity(0.15), location: min(max(lastPosition, 0), 1)),
            Gradient.Stop(color: color.opacity(0.15), location: 1.1)
        ])

        let multiLineGradient = Gradient(stops: [
            Gradient.Stop(color: .onSurfaceDim.opacity(0.2), location: -1),
            Gradient.Stop(color: .onSurfaceDim.opacity(0.2), location: min(max(firstPosition, 0), 1)),
            Gradient.Stop(color: color, location: min(max(firstPosition, 0), 1)),
            Gradient.Stop(color: color, location: min(max(lastPosition, 0), 1)),
            Gradient.Stop(color: .onSurfaceDim.opacity(0.2), location: min(max(lastPosition, 0), 1)),
            Gradient.Stop(color: .onSurfaceDim.opacity(0.2), location: 1)
        ])

        let singleFillGradient = Gradient(stops: [
            Gradient.Stop(color: color, location: 0),
            Gradient.Stop(color: color, location: 1)
        ])

        let multiFillGradient = Gradient(stops: [
            Gradient.Stop(color: .onSurfaceDim.opacity(0.25), location: -1),
            Gradient.Stop(color: .onSurfaceDim.opacity(0.25), location: min(max(firstPosition, 0), 1)),
            Gradient.Stop(color: color, location: min(max(firstPosition, 0), 1)),
            Gradient.Stop(color: color, location: min(max(lastPosition, 0), 1)),
            Gradient.Stop(color: .onSurfaceDim.opacity(0.25), location: min(max(lastPosition, 0), 1)),
            Gradient.Stop(color: .onSurfaceDim.opacity(0.25), location: 1)
        ])
        
        let lineGradient: Gradient = {
            if dragPositions.count == 2 && isDragging {
                return multiLineGradient
            } else if dragPositions.count == 1 && isDragging {
                return singleHoverLineGradient
            } else {
                return singleLineGradient
            }
        }()
        
        let fillGradient = dragPositions.count == 2 && isDragging ? multiFillGradient : singleFillGradient
        let mask = LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.05)], startPoint: .top, endPoint: .bottom)
        let rp = realPrices
        
        ZStack {
            ChartLineShape(prices: rp)
                .stroke(
                    LinearGradient(gradient: lineGradient, startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, dash: dash)
                )
                .accessibilityHidden(true)
            
            if isGraphFilled {
                ChartAreaShape(prices: rp)
                    .fill(LinearGradient(gradient: fillGradient, startPoint: .leading, endPoint: .trailing))
                    .mask { mask }
                    .accessibilityHidden(true)
            }
        }
        .mask(alignment: .leading) {
            GeometryReader { geo in
                Rectangle()
                    .frame(width: geo.size.width * trimEnd)
            }
        }
        .clipped()
        .overlay {
            if showLivePriceIndicator, !isDragging, let point = lastPoint(in: rp) {
                GeometryReader { geo in
                    PulsingDot(color: color, diameter: 6)
                        .position(
                            x: point.x * geo.size.width,
                            y: point.y * geo.size.height
                        )
                        .opacity(Double(trimEnd))
                }
                .accessibilityHidden(true)
            }
        }
        #if DEBUG
        .onAppear {
            withAnimation(.easeInOut(duration: 3).delay(1)) {
                trimEnd = 1
            }
        }
        #endif
    }
}

#elseif IS_WIDGET
struct PriceLineChartView: View {
    @Environment(\.colorScheme) var scheme

    let prices: [Double]
    let color: Color?
    var lineWidth: CGFloat = 1
    var dropCount: Int = 0
    
    private var realPrices: [Double] {
        guard !prices.isEmpty, let firstPrice = prices.first else { return [] }
        var allSame = true
        var minValue = Double.infinity
        var maxValue = -Double.infinity
        
        for price in prices {
            if price != -1 {
                if price < minValue { minValue = price }
                if price > maxValue { maxValue = price }
                if price != firstPrice {
                    allSame = false
                }
            }
        }
        
        if allSame && minValue != Double.infinity {
            return [0, 0]
        }
        
        guard minValue != Double.infinity && maxValue != -Double.infinity else {
            return [0, 0]
        }
        
        let range = maxValue - minValue
        if range == 0 {
            return [0, 0]
        }
        
        let normalized = prices.map { price in
            price == -1 ? -1 : (price - minValue) / range
        }
        
        return Array(normalized.dropLast(dropCount))
    }

    var body: some View {
        let color = color ?? Color.secondary

        let singleLineGradient = Gradient(stops: [
            Gradient.Stop(color: color, location: 0),
            Gradient.Stop(color: color, location: 1)
        ])
        
        let singleFillGradient = Gradient(stops: [
            Gradient.Stop(color: color, location: 0),
            Gradient.Stop(color: color, location: 1)
        ])
        
        let mask = LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.0)], startPoint: .top, endPoint: .bottom)
        let rp = realPrices
        
        ZStack {
            ChartLineShape(prices: rp)
                .stroke(
                    LinearGradient(gradient: singleLineGradient, startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
            
            ChartAreaShape(prices: rp)
                .fill(LinearGradient(gradient: singleFillGradient, startPoint: .leading, endPoint: .trailing))
                .mask { mask }
        }
        .clipped()
    }
}
#endif

private struct PulsingDot: View {
    let color: Color
    var diameter: CGFloat = 6

    @State private var animating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: diameter, height: diameter)
                .scaleEffect(animating ? 3 : 1)
                .opacity(animating ? 0 : 0.75)

            Circle()
                .fill(color)
                .frame(width: diameter, height: diameter)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                animating = true
            }
        }
    }
}

private struct ChartLineShape: Shape {
    let prices: [Double]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard prices.count > 1 else { return path }
        
        let step = rect.width / CGFloat(prices.count - 1)
        var needsMove = true
        
        for (index, value) in prices.enumerated() {
            guard value != -1 else { needsMove = true; continue }
            let point = CGPoint(
                x: rect.minX + CGFloat(index) * step,
                y: rect.minY + (1 - value) * rect.height
            )
            if needsMove {
                path.move(to: point)
                needsMove = false
            } else {
                path.addLine(to: point)
            }
        }
        
        return path
    }
}

private struct ChartAreaShape: Shape {
    let prices: [Double]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard prices.count > 1 else { return path }
        
        let step = rect.width / CGFloat(prices.count - 1)
        var needsMove = true
        var firstValidX: CGFloat?
        var lastValidX: CGFloat?
        
        for (index, value) in prices.enumerated() {
            guard value != -1 else { needsMove = true; continue }
            let x = rect.minX + CGFloat(index) * step
            let y = rect.minY + (1 - value) * rect.height
            if needsMove {
                path.move(to: CGPoint(x: x, y: y))
                needsMove = false
                if firstValidX == nil { firstValidX = x }
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            lastValidX = x
        }
        
        if let lastX = lastValidX, let firstX = firstValidX {
            path.addLine(to: CGPoint(x: lastX, y: rect.maxY))
            path.addLine(to: CGPoint(x: firstX, y: rect.maxY))
            path.closeSubpath()
        }
        
        return path
    }
}
