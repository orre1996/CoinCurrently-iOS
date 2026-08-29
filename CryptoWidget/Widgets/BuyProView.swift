//
//  BuyProView.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 6/18/26.
//

import SwiftUI
import WidgetKit

struct BuyProView: View {
    @Environment(\.colorScheme) var scheme
    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    let hasBoughtPro: Bool
    var fromLockScreen: Bool = false

    private var contentSpacing: CGFloat {
        switch widgetFamily {
        case .systemSmall:
            return 8
        case .systemMedium:
            return 16
        case .systemLarge:
            return 32
        default:
            return 16
        }
    }
    
    var body: some View {
        ZStack {
            if !hasBoughtPro {
                VStack(spacing: contentSpacing) {
                    Text("Available with\nCoinCurrently Pro")
                        .font(.satoshiBold(16))
                        .foregroundStyle(Color.onSurface(for: .dark))
                        .fixedSize()
                        .multilineTextAlignment(.center)
                    
                    if !fromLockScreen {
                        upgradeButton
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Color.black.opacity(widgetRenderingMode == .fullColor ? 0.6 : 0.35)
                )
            }
        }
    }

    @ViewBuilder
    private var upgradeButton: some View {
        let label = Text("Upgrade now")
            .font(.satoshiBold(18))
            .fixedSize()
            .padding(
                EdgeInsets(
                    top: 12,
                    leading: 24,
                    bottom: 12,
                    trailing: 24
                )
            )

        if widgetRenderingMode == .fullColor {
            label
                .foregroundStyle(Color.onPrimary(for: .dark))
                .background(Color.primary(for: .dark))
                .clipShape(Capsule())
        } else {
            label
                .overlay {
                    Capsule()
                        .strokeBorder(lineWidth: 2)
                        .widgetAccentable()
                }
        }
    }
}
