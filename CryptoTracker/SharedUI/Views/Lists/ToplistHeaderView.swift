//
//  ToplistHeaderView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 3/29/25.
//

import SwiftUI

struct ToplistHeaderView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let selectedChangeOption: PriceChange
    
    private var isHorizontal: Bool {
        return !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        HStack(spacing: 16) {
            MinimumTextSize(text: "9999") {
                Text(Localization.string("#"))
                    .font(.satoshiMedium(14))
            }
            .font(.satoshiBold(16))
            .lineLimit(1)
            
            Text(Localization.string(isHorizontal ? "Coin" : "Coin / Price"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isHorizontal {
                Text(Localization.string("Price"))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            MinimumTextSize(
                text: "999.9%",
                // Size of triangle + padding
                extraSize: 16 * min(scale, 1.5) + 4,
                alignment: .trailing
            ) {
                Text("\(Localization.string(selectedChangeOption.rawValue)) %")
                    .font(.satoshiBold(14))
            }
            .lineLimit(1)
            .font(.satoshiBold(16))
            .frame(alignment: .trailing)
        }
        .font(.satoshiMedium(14))
        .foregroundStyle(Color.onSurfaceDim)
        .padding(
            EdgeInsets(
                top: 16,
                leading: 16 + safeAreaInsets.leading,
                bottom: 0,
                trailing: 16 + safeAreaInsets.trailing
            )
        )
        .background(Color.surface)
        .accessibilityHidden(true)
    }
}
