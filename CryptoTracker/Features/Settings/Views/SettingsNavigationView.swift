//
//  SettingsNavigationView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-17.
//

import SwiftUI

struct SettingsNavigationView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category

    @ScaledMetric private var scale: CGFloat = 1

    let title: String
    var subTitle: String? = nil
    var accessibilityText: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Localization.string(title))
                        .font(.satoshiBold(16))
                        .foregroundStyle(Color.onSurface)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subTitle {
                        Text(Localization.string(subTitle))
                            .font(.satoshiBold(12))
                            .foregroundStyle(Color.onSurfaceDimmer)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, subTitle == nil ? 12 : 0)

                Image.chevronRight
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .scaledToFill()
                    .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5), alignment: .center)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Color.onSurface)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityText ?? Localization.string(title))
            .padding(.trailing, 8)
        }
        .multilineTextAlignment(.leading)
    }
}
