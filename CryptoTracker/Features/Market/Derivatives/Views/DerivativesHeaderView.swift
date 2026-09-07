//
//  NFTsHeaderView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 12/2/25.
//

import SwiftUI

struct DerivativesHeaderView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Text(isHorizontal ? "Exchange" : "Exchange / Open Interest")
                .font(.satoshiMedium(14))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isHorizontal {
                Text("Open Interest")
                    .font(.satoshiMedium(14))
                    .lineLimit(1)
            }
            
            Text("24h Volume")
                .font(.satoshiMedium(14))
                .lineLimit(isHorizontal ? 1 : nil)
                .frame(alignment: .trailing)
                .multilineTextAlignment(.trailing)
        }
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
