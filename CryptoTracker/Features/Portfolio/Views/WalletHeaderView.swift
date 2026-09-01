//
//  ToplistHeaderView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 3/29/25.
//

import SwiftUI

struct WalletHeaderView: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Text(isHorizontal ? "Coin" : "Coin / Holdings")
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(isHorizontal ? 1 : nil)
                .multilineTextAlignment(.leading)
            
            if isHorizontal {
                Text("Holdings")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 8)
            }
            
            MinimumTextSize(
                text: "999.9%",
                extraSize: 16 * min(scale, 1.5) + 4,
                alignment: .trailing
            ) {
                Text("7d %")
                    .font(.satoshiMedium(14))
            }
            .lineLimit(1)
            .font(.satoshiBold(16))
            .frame(alignment: .trailing)
        }
        .lineLimit(1)
        .font(.satoshiMedium(14))
        .foregroundStyle(Color.onSurfaceDim)
        .background(Color.surface)
        .accessibilityHidden(true)
    }
}
