//
//  HoverTextView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-09.
//

import SwiftUI

struct HoverTextView: View {
    let isDragging: Bool
    let hoverTime: String
    var hoverPrice: Double = 0.0
    let readerSize: CGSize
    let prices: [Double]
    let xPositionTime: CGFloat
    let xPositionPrice: CGFloat
    var fromFearGreed = false
    var forceCurrency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    
    @Binding var hoverTimeWidthSize: CGFloat
    @Binding var hoverPriceWidthSize: CGFloat

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(isDragging ? hoverTime : "")
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.none, value: UUID())
                    .readSize {
                        hoverTimeWidthSize = $0.width
                    }
                    .opacity(isDragging ? 1 : 0)
                    .animation(.default, value: isDragging)
                    .offset(x: readerSize == .zero ? 0 : xPositionTime - hoverTimeWidthSize / 2)
                
                Text(isDragging ? fromFearGreed ? "\(Int(hoverPrice))" : hoverPrice.formatted(style: .compact(from: .million, currency: forceCurrency)) : "")
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.none, value: UUID())
                    .readSize {
                        hoverPriceWidthSize = $0.width
                    }
                    .opacity(isDragging ? 1 : 0)
                    .animation(.default, value: isDragging)
                    .offset(x: readerSize == .zero ? 0 : xPositionPrice - hoverTimeWidthSize / 2)
            }
            
            // To always have right height of view
            VStack(spacing: 2) {
                Text("%")
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0)
                
                Text("%")
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundColor(.onSurface)
        .font(.poppinsRegular(18))
        .lineLimit(1)
    }
}

struct ChartHoverLabelsView: View {
    let hoverTime: String
    let hoverPrice: String
    let xPositionTime: CGFloat
    let xPositionPrice: CGFloat
    
    @Binding var hoverTimeWidthSize: CGFloat
    @Binding var hoverPriceWidthSize: CGFloat

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(hoverTime)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.none, value: UUID())
                    .readSize {
                        hoverTimeWidthSize = $0.width
                    }
                    .offset(x: xPositionTime)
                
                Text(hoverPrice)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.none, value: UUID())
                    .readSize {
                        hoverPriceWidthSize = $0.width
                    }
                    .offset(x: xPositionPrice)
            }
            
            // To always have right height of view
            VStack(spacing: 2) {
                Text("%")
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0)
                
                Text("%")
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundColor(.onSurface)
        .font(.poppinsRegular(18))
        .lineLimit(1)
    }
}
