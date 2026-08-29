//
//  NFTsHeaderView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 12/2/25.
//

import SwiftUI

struct NFTsHeaderView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    private var isHorizontal: Bool {
        return !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(isHorizontal ? "Collection" : "Collection / Floor Price")
                .font(.satoshiMedium(14))
                .frame(maxWidth: isHorizontal ? nil : .infinity, alignment: .leading)
            
            if isHorizontal {
                Text("Floor Price")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 8)
            }
            
            MinimumTextSize(
                text: "999.9%",
                // Size of triangle + padding
                extraSize: 16 * min(scale, 1.5) + 4,
                alignment: .trailing
            ) {
                Text("24h %")
                    .font(.satoshiMedium(14))
            }
            .lineLimit(1)
            .font(.satoshiBold(16))
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
