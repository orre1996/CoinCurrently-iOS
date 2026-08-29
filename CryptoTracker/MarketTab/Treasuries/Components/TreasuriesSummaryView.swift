//
//  TreasuriesSummaryView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/22/26.
//

import SwiftUI

struct TreasuriesSummaryView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category

    let totalHoldings: Double?
    let marketCapDominance: Double?
    let coinSymbol: String?

    var body: some View {
        let isHorizontal = category.isAccessibilityCategory && verticalSizeClass == .regular

        VStack(alignment: .leading, spacing: 4) {
            Text("Total Holdings")
                .font(.satoshiBold(18))
                .foregroundStyle(Color.onSurfaceDim)

            NewShimmeringText(
                text: formattedTotalHoldings(isHorizontal: isHorizontal),
                isDownloading: totalHoldings == nil
            )
            .font(.satoshiBold(36))
            .foregroundStyle(Color.onSurface)

            dominanceView
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(summaryAccessibilityLabel(isHorizontal: isHorizontal))
    }

    @ViewBuilder
    private var dominanceView: some View {
        let roundedDominance = (marketCapDominance ?? 0).roundTo(places: 2)
        let formattedDominance = roundedDominance.formatted(.number.precision(.fractionLength(2)))

        OverflowLayout(spacing: 4) {
            Text("Market Cap Dominance")
                .font(.satoshiBold(12))
                .foregroundStyle(Color.onSurfaceDim)

            NewShimmeringText(
                text: "\(formattedDominance)%",
                isDownloading: marketCapDominance == nil
            )
            .foregroundStyle(Color.onSurface)
            .font(.satoshiBold(12))
        }
    }

    private func formattedTotalHoldings(isHorizontal: Bool) -> String {
        let value = totalHoldings ?? 1_272_129.0

        return value.formatCurrency(
            threshold: isHorizontal ? .million : FormattingThreshold.none,
            currency: holdingsCurrency
        )
    }

    private var holdingsCurrency: CurrencyModel {
        CurrencyModel(
            currency: "",
            code: "",
            symbol: coinSymbol?.uppercased() ?? "BTC",
            locale: "en_US",
            suffix: true
        )
    }

    private func summaryAccessibilityLabel(isHorizontal: Bool) -> String {
        let holdingsText = (totalHoldings ?? 0).formatCurrency(
            threshold: isHorizontal ? .million : FormattingThreshold.none,
            currency: holdingsCurrency,
            accessible: true
        )
        let dominanceText = (marketCapDominance ?? 0).numberAccessible(maxPlaces: 2)

        return "Total Holdings: \(holdingsText). Market Cap Dominance: \(dominanceText) percent"
    }
}
