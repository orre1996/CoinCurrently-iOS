//
//  NewMultiHoverTextView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/4/26.
//

import SwiftUI

struct NewMultiHoverTextView: View {
    let hoverTimes: [String]
    let differenceValue: String
    let differencePercent: String
    let color: Color
    let xPosition: CGFloat

    @Binding var hoverTimeWidthSize: CGFloat
    
    var body: some View {
        ZStack {
            HStack(alignment: .center, spacing: 12) {
                VStack(spacing: 4) {
                    Text(differenceValue)
                        .foregroundColor(color)
                        .font(.satoshiBold(16))
                    
                    Text(hoverTimes[safely: 0] ?? "")
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .font(.satoshiBold(12))
                }
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
                
                Text("-")
                    .layoutPriority(1)
                    .fixedSize(horizontal: false, vertical: true)
                
                VStack(spacing: 4) {
                    Text(differencePercent)
                        .foregroundColor(color)
                        .font(.satoshiBold(16))
                    
                    Text(hoverTimes[safely: 1] ?? "")
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .font(.satoshiBold(12))
                }
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            }
            .padding(
                EdgeInsets(
                    top: 4,
                    leading: 8,
                    bottom: 4,
                    trailing: 8
                )
            )
            .minimumScaleFactor(0.7)
            .readSize {
                hoverTimeWidthSize = $0.width
            }
            .background(Color.surfaceContainer)
            .cornerRadius(4)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .animation(.none, value: UUID())
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundColor(.onSurface)
        .offset(x: xPosition)
        .padding(.horizontal, 16)
        .lineLimit(1)
        .zIndex(3)
    }
}
