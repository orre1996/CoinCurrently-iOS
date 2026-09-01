//
//  SettingsPickerView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-17.
//

import SwiftUI

struct SettingsPickerView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category

    @ScaledMetric private var scale: CGFloat = 1

    let title: String
    let accessibilityTitle: String?
    let startIndex: Int
    let texts: [String]
    let accessiblityTexts: [String]
    let forceOneRow: Bool
    let valueChanged: (Int) -> Void
    
    var body: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact

        AdaptiveStack(isHorizontal: forceOneRow && (isHorizontal), spacing: isHorizontal ? 8 : 4, horizontalAlignment: .leading) {
            Text(title)
                .font(.poppinsRegular(16))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(accessibilityTitle ?? title)
                .layoutPriority(1)
            
            Spacer(minLength: 0)
            
            CustomPickerSelector(
                selectedIndex: startIndex,
                texts: texts,
                accessibilityTexts: accessiblityTexts,
                canScaleDown: !forceOneRow,
                setHeight: !forceOneRow,
                extraSmall: !forceOneRow,
                oneRow: false
            ) { index in
                valueChanged(index)
            }
            .layoutPriority(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardBackground())
        .padding(.horizontal, 16)
    }
}
