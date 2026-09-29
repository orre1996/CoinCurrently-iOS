//
//  NFTsHeaderView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 12/2/25.
//

import SwiftUI

struct ExchangesHeaderView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    private var isHorizontal: Bool {
        !category.isAccessibilityCategory || verticalSizeClass == .compact
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Text(Localization.string(isHorizontal ? "Exchange" : "Exchange / 24h Volume"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isHorizontal {
                Text(Localization.string("24h Volume"))
            }
            
            MinimumTextSize(
                text: "10/10",
                alignment: .trailing
            ) {
                Text(Localization.string("Trust"))
                    .font(.satoshiMedium(14))
            }
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
