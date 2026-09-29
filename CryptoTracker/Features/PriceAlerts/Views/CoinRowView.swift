//
//  CoinRowView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-21.
//

import SwiftUI

struct CoinRowView: View {
    @ScaledMetric private var scale: CGFloat = 1

    let coin: Toplist
    let index: Int
    let totalCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(alignment: .top, spacing: 16) {
                if let url = coin.image {
                    ShimmeringImage(imageUrl: url,
                                    downloading: coin.image == nil,
                                    size: 32 * min(scale, 1.5))
                    .accessibilityHidden(true)
                }

                Text("\(coin.name ?? "") (\(coin.symbol?.uppercased() ?? ""))")
                    .font(.poppinsRegular(16))
                    .foregroundColor(.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 32 * min(scale, 1.5), alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
        .modifier(CardBackground())
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Localization.format("Currency %d of %d. %@.", index + 1, totalCount, coin.name ?? ""))
    }
}

#Preview {
    CoinRowView(coin: Toplist(),
                index: 0,
                totalCount: 0,
                action: { })
}
