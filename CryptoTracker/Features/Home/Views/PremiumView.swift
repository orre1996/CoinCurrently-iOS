//
//  PremiumView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-31.
//

import SwiftUI

struct PremiumView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let title: String
    let message: String
    let accessibleMessage: String?
    let timeLeft: String?
    let timeLeftDate: Date?
    let viewPressed: () -> Void
    let closeAction: (String) -> Void
    
    var body: some View {
        Button(action: {
            viewPressed()
        }, label: {
            HStack(spacing: 16) {
                Image.premiumLogo
                    .resizable()
                    .frame(width: 84, height: 84)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(Localization.string(title))
                        .font(.satoshiBold(22))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.trailing, 4 + 24 * min(scale, 1.5))
                        .padding(.bottom, 4)
                    
                    Text(Localization.string(message))
                        .font(.satoshiRegular(16))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color.onSurfaceDim)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)

                    if let timeLeft, title == "Welcome Offer!" {
                        Text(timeLeft)
                            .font(.satoshiRegular(14))
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(Color.onSurfaceDim)
                    }
                }
                .accessibilityHidden(true)
            }
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .cardBackground(backgroundColor: .surfaceContainer)
        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        .foregroundStyle(Color.onSurface)
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .padding(
            EdgeInsets(
                top: 0,
                leading: 16 + safeAreaInsets.leading,
                bottom: 32,
                trailing: 16 + safeAreaInsets.trailing
            )
        )
    }
    
    private var closeButton: some View {
        Button(action: {
            closeAction(message)
        }, label: {
            Image.cross
                .resizable()
                .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                .padding(12)
        })
        .padding(4)
        .accessibilityLabel(Localization.string("Hide offer"))
    }
    
    private var accessibilityLabelText: String {
        if let accessibleMessage, !accessibleMessage.isEmpty {
            return accessibleMessage
        }
        
        let localizedTitle = Localization.string(title)
        let localizedMessage = Localization.string(message)
        
        if let timeLeft, title == "Welcome Offer!" {
            return "\(localizedTitle). \(localizedMessage). \(timeLeft)"
        }
        
        return "\(localizedTitle). \(localizedMessage)"
    }
}
