//
//  SettingsToggleLockedView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-17.
//

import SwiftUI

struct SettingsToggleLockedView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category

    @ScaledMetric private var scale: CGFloat = 1

    let title: String
    let subTitle: String
    let isOn: Bool
    let action: () -> Void

    private let onColor = Color.primary
    private let offColor = Color.surface
    private let thumbColor = Color.onSurface
    
    var body: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact

        AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8, horizontalAlignment: .leading) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.string(title))
                    .font(.satoshiBold(16))
                    .foregroundStyle(Color.onSurface)
                
                Text(Localization.string(subTitle))
                    .font(.satoshiBold(12))
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            LockedToggle(
                isOn: isOn,
                action: action
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityRemoveTraits(.isButton)
        .accessibilityLabel(Localization.format("%@, switch button", Localization.string(title)))
        .accessibilityHint(Localization.string(subTitle))
        .accessibilityValue(Localization.string(isOn ? "On" : "Off"))
        .accessibilityAction {
            action()
        }
    }
}
