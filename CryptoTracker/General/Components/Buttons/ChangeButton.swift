//
//  CurrencyButton.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-04-20.
//

import SwiftUI

struct ChangeButton: View {
    @ScaledMetric private var scale: CGFloat = 1

    let direction: ChangeDirection
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 8) {
                Text(direction.symbol)
                    .font(.satoshiBold(18))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .foregroundStyle(direction.color)
                    .fixedSize(horizontal: false, vertical: true)
                
                Image.trendDown
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.onSurfaceContainer)
                    .scaledToFill()
                    .frame(width: 20 * min(scale, 1.5), height: 20 * min(scale, 1.5))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Change direction, currently selected: \(direction.rawValue)")
        }
    }
}
