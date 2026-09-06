//
//  MarketShareView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/6/25.
//

import SwiftUI

struct MarketShareView: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    let coin: Percentages?
    let color: Color
    let listIndex: Int
    let listCount: Int
    
    var body: some View {
        HStack(spacing: 4) {
            circleView

            ShimmeringText(
                text: coin?.symbol.uppercased() ?? "000",
                isDownloading: coin == nil
            )
            .foregroundStyle(Color.onSurface)

            ShimmeringText(
                text: "\(roundedChange.formatted(.number.precision(.fractionLength(2))))%",
                isDownloading: coin?.percentage == nil
            )
            .foregroundStyle(Color.onSurfaceDim)
        }
        .font(.satoshiBold(12))
        .padding(
            EdgeInsets(
                top: 4,
                leading: 8,
                bottom: 4,
                trailing: 8
            )
        )
        .frame(minWidth: 106, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
    }
    
    private var roundedChange: Double {
        ((coin?.percentage ?? 0) * 100).roundTo(places: 2)
    }
    
    private var accessibilityLabelText: String {
        let symbol = coin?.symbol ?? ""
        let accessibleSymbol = symbol == "OTHER" ? symbol : symbol.symbolAccessible
        let accessibleChange = roundedChange.numberAccessible(maxPlaces: 2)
        
        return "Currency \(listIndex + 1) of \(listCount): \(accessibleSymbol). Market share: \(accessibleChange) percent"
    }
    
    private var circleView: some View {
        ZStack {
            Circle()
                .frame(width: 12 * min(scale, 1.5), height: 12 * min(scale, 1.5))
                .foregroundColor(coin == nil ? Color.shimmeringBackground.opacity(0.15) : color)
            
            if coin == nil {
                Circle()
                    .frame(width: 12 * min(scale, 1.5), height: 12 * min(scale, 1.5))
                    .foregroundColor(.onSurface.opacity(0.25))
                    .shimmer()
            }
        }
    }
}
