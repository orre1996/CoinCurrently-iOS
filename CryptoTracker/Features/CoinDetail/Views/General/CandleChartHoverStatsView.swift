//
//  CandleChartHoverStatsView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 8/22/25.
//

import SwiftUI

struct CandleChartHoverStatsView: View {
    let currentCandle: CurrentChartHover?
    let xPosition: CGFloat
    
    @Binding var hoverCandleTimeWidthSize: CGFloat

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(Localization.string("Open"))
                            .foregroundStyle(Color.onSurfaceDimmer)
                        
                        Text(currentCandle?.open.formatCurrency(threshold: FormattingThreshold.none) ?? "")
                            .foregroundStyle(Color.onSurface)
                    }
                    
                    HStack(spacing: 4) {
                        Text(Localization.string("Close price"))
                            .foregroundStyle(Color.onSurfaceDimmer)
                        
                        Text(currentCandle?.close.formatCurrency(threshold: FormattingThreshold.none) ?? "")
                            .foregroundStyle(Color.onSurface)
                    }
                }
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(Localization.string("High"))
                            .foregroundStyle(Color.onSurfaceDimmer)
                        
                        Text(currentCandle?.high.formatCurrency(threshold: FormattingThreshold.none) ?? "")
                            .foregroundStyle(Color.onSurface)
                    }
                    
                    HStack(spacing: 4) {
                        Text(Localization.string("Low"))
                            .foregroundStyle(Color.onSurfaceDimmer)
                        
                        Text(currentCandle?.low.formatCurrency(threshold: FormattingThreshold.none) ?? "")
                            .foregroundStyle(Color.onSurface)
                    }
                }
            }
            
            Text(currentCandle?.time ?? "")
                .foregroundStyle(Color.onSurfaceDimmer)
        }
        .font(.satoshiBold(12))
        .fixedSize(horizontal: false, vertical: true)
        .animation(.none, value: UUID())
        .padding(
            EdgeInsets(
                top: 4,
                leading: 8,
                bottom: 4,
                trailing: 8
            )
        )
        .readSize {
            hoverCandleTimeWidthSize = $0.width
        }
        .background(Color.surfaceContainer)
        .cornerRadius(4)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .offset(x: xPosition)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .foregroundColor(.onSurface)
        .lineLimit(1)
        .zIndex(3)
    }
}
