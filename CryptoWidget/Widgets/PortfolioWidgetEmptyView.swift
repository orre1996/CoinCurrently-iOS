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

    var body: some View {
        ZStack {
            addTransactionButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .widgetURL(URL(string: "portfolio"))
    }

    @ViewBuilder
    private var addTransactionButton: some View {
        let label = Text("Add Transaction")
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

#Preview {
    PortfolioWidgetEmptyView()
}
