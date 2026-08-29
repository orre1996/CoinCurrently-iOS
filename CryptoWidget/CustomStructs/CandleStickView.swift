//
//  CandleStickView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-07-30.
//

import SwiftUI

struct CandleStickView: View {
    let candles: [Candle]?
    let viewWidth: CGFloat
    
    private struct NormalizedCandle {
        let open: Double
        let high: Double
        let low: Double
        let close: Double
        let color: Color
    }
    
    private var normalizedCandles: [NormalizedCandle] {
        guard let candles, !candles.isEmpty else { return [] }
        
        let globalMax = candles.max(by: { ($0.high ?? 0.0) < ($1.high ?? 0.0) })?.high ?? 0.0
        let globalMin = candles.min(by: { ($0.low ?? 0.0) < ($1.low ?? 0.0) })?.low ?? 0.0
        let range = globalMax - globalMin
        
        return candles.map { candle in
            let open = candle.open ?? 0
            let high = candle.high ?? 0
            let low = candle.low ?? 0
            let close = candle.close ?? 0
            
            let color: Color
            if open == close {
                color = .onSurfaceDim
            } else if open > close {
                color = .trendDown
            } else {
                color = .trendUp
            }
            
            guard range > 0, !(open == 1 && high == 1 && low == 1 && close == 1) else {
                return NormalizedCandle(open: 0.5, high: 0.5, low: 0.5, close: 0.502, color: color)
            }
            
            let normOpen = (open - globalMin) / range
            let normHigh = (high - globalMin) / range
            let normLow = (low - globalMin) / range
            var normClose = (close - globalMin) / range
            
            if normOpen == normClose {
                normClose += 0.002
            }
            
            return NormalizedCandle(open: normOpen, high: normHigh, low: normLow, close: normClose, color: color)
        }
    }
    
    var body: some View {
        Canvas { context, size in
            let data = normalizedCandles
            guard !data.isEmpty else { return }
            
            let candleWidth = size.width / CGFloat(data.count)
            
            for (index, candle) in data.enumerated() {
                let x = CGFloat(index) * candleWidth
                let shading = GraphicsContext.Shading.color(candle.color)
                
                var stemPath = Path()
                stemPath.move(to: CGPoint(x: x + candleWidth * 0.5, y: (1 - candle.high) * size.height))
                stemPath.addLine(to: CGPoint(x: x + candleWidth * 0.5, y: (1 - candle.low) * size.height))
                context.stroke(stemPath, with: shading, lineWidth: 1)
                
                let openY = (1 - candle.open) * size.height
                let closeY = (1 - candle.close) * size.height
                let bodyPath = Path(CGRect(
                    x: x + 1,
                    y: min(openY, closeY),
                    width: max(0, candleWidth - 2),
                    height: max(0.5, abs(closeY - openY))
                ))
                context.fill(bodyPath, with: shading)
            }
        }
    }
}
