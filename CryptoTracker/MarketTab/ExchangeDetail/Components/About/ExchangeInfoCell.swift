//
//  ExchangeInfoCell.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-03-11.
//

import SwiftUI

struct ExchangeInfoCell: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category

    let exchange: Exchange

    private var hasAnyInfo: Bool {
        exchange.year_established != nil ||
        (exchange.country != nil && !(exchange.country?.isEmpty ?? true)) ||
        exchange.centralized != nil
    }

    private var exchangeTypeText: String {
        guard let centralized = exchange.centralized else { return "—" }
        return centralized ? "Centralized" : "Decentralized"
    }

    var body: some View {
        if hasAnyInfo {
            VStack(alignment: .leading, spacing: 16) {
                Text("Exchange Info")
                    .font(.satoshiBold(22))
                    .foregroundStyle(Color.onSurfaceDim)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 16) {
                    if hasFirstRow {
                        infoRow
                    }
                    
                    if hasSecondRow {
                        if hasFirstRow {
                            Separator()
                        }
                        
                        exchangeTypeRow
                    }
                }
                .cardBackground()
            }
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder
    private var infoRow: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact

        AdaptiveStack(
            isHorizontal: isHorizontal,
            spacing: isHorizontal ? 16 : 12,
            horizontalAlignment: .leading,
            verticalAlignment: .top
        ) {
            if exchange.year_established != nil {
                infoItem(label: "Founded", value: "\(exchange.year_established!)")
            }

            if !isHorizontal && exchange.year_established != nil && (exchange.country != nil && !(exchange.country?.isEmpty ?? true)) {
                Separator()
            }

            if let country = exchange.country, !country.isEmpty {
                infoItem(label: "Headquarters", value: country)
            }
        }
    }

    private var hasFirstRow: Bool {
        exchange.year_established != nil ||
        (exchange.country != nil && !(exchange.country?.isEmpty ?? true))
    }

    private var hasSecondRow: Bool {
        exchange.centralized != nil
    }

    private var exchangeTypeRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Exchange Type")
                .foregroundStyle(Color.onSurfaceDim)
                .font(.satoshiBold(12))
                .accessibilityLabel("Exchange type: ")

            Text(exchangeTypeText)
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func infoItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .foregroundStyle(Color.onSurfaceDim)
                .font(.satoshiBold(12))
                .accessibilityLabel("\(label): ")

            Text(value)
                .foregroundStyle(Color.onSurface)
                .font(.satoshiBold(16))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
