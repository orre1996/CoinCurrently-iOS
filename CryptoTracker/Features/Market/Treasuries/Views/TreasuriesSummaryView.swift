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

            ShimmeringText(
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

            ShimmeringText(
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

    private func accessibleHoldingsCurrency() -> CurrencyModel {
        if let symbol = coinSymbol?.uppercased(),
           let knownCurrency = CurrencyModel.allCurrencies.first(where: { $0.code == symbol }) {
            return knownCurrency
        }

        if let symbol = coinSymbol?.trimmingCharacters(in: .whitespacesAndNewlines),
           !symbol.isEmpty {
            let spelledSymbol = symbol.uppercased().map { String($0) }.joined(separator: " ")
            return CurrencyModel(
                currency: spelledSymbol,
                code: symbol.uppercased(),
                symbol: symbol.uppercased(),
                locale: "",
                suffix: true,
                voiceOverName: spelledSymbol
            )
        }

        return holdingsCurrency
    }

    private func summaryAccessibilityLabel(isHorizontal: Bool) -> String {
        guard totalHoldings != nil || marketCapDominance != nil else {
            return "Loading total holdings"
        }

        let holdingsText = (totalHoldings ?? 0).formatCurrency(
            threshold: isHorizontal ? .million : FormattingThreshold.none,
            currency: accessibleHoldingsCurrency(),
            accessible: true
        )
        let dominanceText = (marketCapDominance ?? 0).numberAccessible(maxPlaces: 2)

        return "Total Holdings: \(holdingsText). Market Cap Dominance: \(dominanceText) percent"
    }
}
