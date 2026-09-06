//
//  SingleHoverStats.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/9/25.
//

import SwiftUI

struct CompareHoverStats: View {
    let mainHoverPrice: String
    let mainSymbol: String?
    let mainPercentChange: Double
    let compareHoverPrice: String
    let compareSymbol: String?
    let comparePercentChange: Double
    let hoverTime: String
    let accessibleTimeframe: String
    let xPositionTime: CGFloat
    
    @Binding var hoverTimeWidthSize: CGFloat

    var body: some View {
        ZStack {
            VStack(spacing: 4) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        CompareRectangleView(
                            color: .primary50,
                            size: 12
                        )
                        
                        Text(mainSymbol?.uppercased() ?? "")
                            .foregroundStyle(Color.onSurfaceDimmer)
                            .font(.satoshiBold(12))
                        
                        Text(mainHoverPrice)
                            .foregroundStyle(Color.onSurface)
                            .font(.satoshiBold(12))
                        
                        if mainHoverPrice == "N/A" {
                            naView
                        } else {
                            PriceChangePercentView(
                                change: mainPercentChange,
                                size: .small,
                                accessibleTimeframe: accessibleTimeframe,
                                isDownloading: false
                            )
                        }
                    }
                    
                    HStack(spacing: 4) {
                        CompareRectangleView(
                            color: .blue50,
                            size: 12
                        )
                        
                        Text(compareSymbol?.uppercased() ?? "")
                            .foregroundStyle(Color.onSurfaceDimmer)
                            .font(.satoshiBold(12))
                        
                        Text(compareHoverPrice)
                            .foregroundStyle(Color.onSurface)
                            .font(.satoshiBold(12))
                        
                        if compareHoverPrice == "N/A" {
                            naView
                        } else {
                            PriceChangePercentView(
                                change: comparePercentChange,
                                size: .small,
                                accessibleTimeframe: accessibleTimeframe,
                                isDownloading: false
                            )
                        }
                    }
                }
                
                Text(hoverTime)
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .font(.satoshiBold(12))
            }
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
                hoverTimeWidthSize = $0.width
            }
            .background(Color.surfaceContainer)
            .cornerRadius(4)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .offset(x: xPositionTime)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .foregroundColor(.onSurface)
        .lineLimit(1)
        .zIndex(3)
    }
    
    private var naView: some View {
        HStack(spacing: 4) {
            Image.trendStill
                .resizable()
                .foregroundStyle(Color.onSurfaceDim)
                .frame(width: 14, height: 14)
            
            Text("N/A")
                .lineLimit(1)
                .font(.satoshiBold(14))
                .foregroundStyle(Color.onSurfaceDim)
        }
    }
}
