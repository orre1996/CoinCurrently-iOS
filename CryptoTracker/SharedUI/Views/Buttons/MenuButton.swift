//
//  CurrencyButton.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-04-20.
//

import SwiftUI

struct MenuButton: View {
    @ScaledMetric private var scale: CGFloat = 1

    let options: [String]
    let selectedOption: String
    let optionChanged: (String) -> Void
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    optionChanged(option)
                }, label: {
                    Text(option.uppercased())
                })
            }
        } label: {
            HStack(spacing: 8) {
                Text(selectedOption.uppercased())
                    .font(.satoshiBold(18))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .foregroundStyle(Color.onSurfaceContainer)
                    .fixedSize(horizontal: false, vertical: true)
                
                Image.trendDown
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.onSurfaceContainer)
                    .scaledToFill()
                    .frame(width: 20 * min(scale, 1.5), height: 20 * min(scale, 1.5))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Localization.format("Change option, currently selected: %@", selectedOption))
    }
}
