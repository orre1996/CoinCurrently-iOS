//
//  ToplistHeaderView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 3/29/25.
//

import SwiftUI

struct PortfolioHeaderView: View {
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
                text: "Profit/Loss",
                alignment: .trailing
            ) {
                Text("Profit/Loss")
                    .font(.satoshiMedium(14))
                    .frame(alignment: .trailing)
            }
            .font(.satoshiBold(16))
        }
        .lineLimit(1)
        .font(.satoshiMedium(14))
        .foregroundStyle(Color.onSurfaceDim)
        .padding(
            EdgeInsets(
                top: 0,
                leading: safeAreaInsets.leading,
                bottom: 16,
                trailing: safeAreaInsets.trailing
            )
        )
        .background(Color.surface)
        .accessibilityHidden(true)
    }
}
