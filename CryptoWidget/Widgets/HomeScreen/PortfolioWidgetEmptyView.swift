//
//  PortfolioWidgetEmptyView.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 6/27/26.
//

import SwiftUI
import WidgetKit

struct PortfolioWidgetEmptyView: View {
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    @Environment(\.widgetFamily) private var family

    var body: some View {
        ZStack {
            addTransactionButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .widgetURL(URL(string: "portfolio"))
    }

    private var isSmallWidget: Bool {
        family == .systemSmall
    }

    @ViewBuilder
    private var addTransactionButton: some View {
        let label = Text(family == .systemSmall ? "Add\nTransaction" : "Add Transaction")
            .font(.satoshiBold(18))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: !isSmallWidget, vertical: true)
            .padding(
                EdgeInsets(
                    top: 12,
                    leading: isSmallWidget ? 16 : 24,
                    bottom: 12,
                    trailing: isSmallWidget ? 16 : 24
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

#Preview {
    PortfolioWidgetEmptyView()
}
