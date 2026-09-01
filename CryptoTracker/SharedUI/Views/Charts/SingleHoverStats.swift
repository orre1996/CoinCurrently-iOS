//
//  SingleHoverStats.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/9/25.
//

import SwiftUI

struct SingleHoverStats: View {
    let hoverPrice: String
    let priceColor: Color
    let hoverTime: String
    let xPositionTime: CGFloat
    
    @Binding var hoverTimeWidthSize: CGFloat
    
    var body: some View {
        VStack(spacing: 4) {
            Text(hoverPrice)
                .foregroundStyle(priceColor)
                .font(.satoshiBold(16))
            
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
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .offset(x: xPositionTime)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .foregroundColor(.onSurface)
        .lineLimit(1)
        .zIndex(3)
    }
}
