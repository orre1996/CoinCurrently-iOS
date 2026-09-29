//
//  SettingsImageView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-17.
//

import SwiftUI

struct SettingsImageView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category

    @ScaledMetric private var scale: CGFloat = 1

    let image: Image?
    var uiimage: UIImage?
    let title: String
    var accessibilityText: String? = nil
    var withArrow: Bool = false
    var withExternalIcon: Bool = false
    var backgroundColor: Color? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact

            HStack(spacing: 16) {
                AdaptiveStack(isHorizontal: isHorizontal, spacing: isHorizontal ? 16 : 8, horizontalAlignment: .leading) {
                    HStack(alignment: .center, spacing: 16) {
                        if let uiimage {
                            Image(uiImage: uiimage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5), alignment: .center)
                                .accessibilityHidden(true)
                                .if(backgroundColor != nil) { view in
                                    view.background(backgroundColor)
                                }
                        } else if let image {
                            image
                                .resizable()
                                .renderingMode(.template)
                                .foregroundStyle(Color.onSurfaceDim)
                                .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5), alignment: .center)
                                .accessibilityHidden(true)
                                .if(backgroundColor != nil) { view in
                                    view.background(backgroundColor)
                                }
                        }
                        
                        Text(Localization.string(title))
                            .font(.poppinsRegular(16))
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(Color.onSurface)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                
                if withArrow {
                    Image.chevronRight
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5), alignment: .center)
                        .accessibilityHidden(true)
                        .foregroundStyle(Color.onSurfaceDimmer)
                } else if withExternalIcon {
                    Image.external
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5), alignment: .center)
                        .accessibilityHidden(true)
                        .foregroundStyle(Color.onSurfaceDimmer)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Localization.string(accessibilityText ?? title))
            .padding(.vertical, 12)
            .padding(.trailing, 8)
        }
    }
}
