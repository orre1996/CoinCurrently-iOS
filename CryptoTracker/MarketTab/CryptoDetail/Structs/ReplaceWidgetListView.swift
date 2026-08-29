//
//  WidgetListView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-18.
//

import SwiftUI

struct ReplaceWidgetListView: View {
    @ScaledMetric private var scale: CGFloat = 1

    let coin: Toplist
    let isSelected: Bool
    let action: (Toplist) -> Void

    var body: some View {
        HStack(spacing: 8) {
            RadioButton(isSelected: isSelected)
                .padding(16)
                .opacity(0)
            
            ShimmeringImage(
                imageUrl: coin.image,
                downloading: false,
                size: 32 * min(scale, 1.5)
            )
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(coin.symbol?.uppercased() ?? "0000")
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurface)
                
                Text(coin.name ?? "0000")
                    .font(.satoshiBold(12))
                    .foregroundStyle(Color.onSurfaceDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.black.opacity(0.001))
        .padding(12)
        .background(isSelected ? Color.surfaceContainer : Color.clear)
        .cornerRadius(8)
        .onTapGesture {
            action(coin)
        }
    }
}
