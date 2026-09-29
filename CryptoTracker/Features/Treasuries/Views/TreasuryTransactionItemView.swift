//
//  TreasuryTransactionItemView.swift
//  CoinCurrently
//

import SwiftUI

struct TreasuryTransactionItemView: View {
    @ScaledMetric private var scale: CGFloat = 1

    let transaction: TreasuryTransaction?
    let coin: Toplist?

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            MinimumTextSize(
                text: "Dec 31, 2025",
                alignment: .leading
            ) {
                ShimmeringText(
                    text: formattedDate,
                    isDownloading: transaction == nil
                )
                .font(.satoshiBold(14))
            }
            .font(.satoshiMedium(16))
            .foregroundStyle(Color.onSurface)
            .accessibilityHidden(true)

            HStack(spacing: 4) {
                ShimmeringImage(
                    imageUrl: coin?.image,
                    downloading: transaction != nil && coin == nil,
                    size: 20 * min(scale, 1.5)
                )
                .accessibilityHidden(true)

                ShimmeringText(
                    text: coinName,
                    isDownloading: transaction == nil
                )
                .font(.satoshiBold(16))
                .foregroundStyle(Color.onSurface)
                .accessibilityHidden(true)
            }
            .padding(.trailing, 12)

            VStack(alignment: .trailing, spacing: 0) {
                ShimmeringText(
                    text: balanceText,
                    isDownloading: transaction == nil
                )
                .font(.satoshiBold(16))
                .foregroundStyle(Color.onSurface)

                ShimmeringText(
                    text: netChangeText,
                    isDownloading: transaction == nil
                )
                .font(.satoshiBold(12))
                .foregroundStyle(netChangeColor)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .multilineTextAlignment(.trailing)
            .accessibilityHidden(true)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
    }

    private var formattedDate: String {
        guard let timestamp = transaction?.date else { return "000000" }
        return Date(timeIntervalSince1970: timestamp / 1000).localizedDescription(
            dateStyle: .medium,
            timeStyle: .none,
            locale: Localization.locale
        )
    }

    private var coinName: String {
        coin?.name ?? transaction?.coin_id?.capitalized ?? "00000"
    }

    private var balanceText: String {
        let balance = transaction?.holding_balance ?? 843_738
        return balance.formatCurrency(
            threshold: FormattingThreshold.none,
            currency: holdingsCurrency
        )
    }

    private var netChangeText: String {
        let change = transaction?.holding_net_change ?? 24_869
        let formatted = abs(change).formatCurrency(
            threshold: FormattingThreshold.none,
            currency: holdingsCurrency
        )
        let sign = change > 0 ? "+" : change < 0 ? "-" : ""
        return "\(sign)\(formatted)"
    }

    private var netChangeColor: Color {
        (transaction?.holding_net_change ?? 0).changeColor
    }

    private var holdingsCurrency: CurrencyModel {
        let symbol = coin?.symbol?.uppercased()
            ?? transaction?.coin_id?.uppercased()
            ?? ""

        return CurrencyModel(
            currency: "",
            code: "",
            symbol: symbol,
            locale: "en_US",
            suffix: true
        )
    }

    private func accessibleHoldingsCurrency() -> CurrencyModel {
        let symbol = coin?.symbol?.uppercased()
            ?? transaction?.coin_id?.uppercased()

        if let symbol,
           let knownCurrency = CurrencyModel.allCurrencies.first(where: { $0.code == symbol }) {
            return knownCurrency
        }

        if let symbol, !symbol.isEmpty {
            let spelledSymbol = symbol.map { String($0) }.joined(separator: " ")
            return CurrencyModel(
                currency: spelledSymbol,
                code: symbol,
                symbol: symbol,
                locale: "",
                suffix: true,
                voiceOverName: spelledSymbol
            )
        }

        return holdingsCurrency
    }

    private var accessibilityDate: String {
        guard let timestamp = transaction?.date else { return formattedDate }
        return Date(timeIntervalSince1970: timestamp / 1000)
            .formatted(.dateTime.weekday(.wide).month(.wide).day().year().locale(Localization.locale))
    }

    private var accessibilityLabelText: String {
        guard let transaction else { return Localization.string("Loading transaction") }

        var components = [accessibilityDate]

        if let type = transaction.type {
            components.append(Localization.string(type == .buy ? "Buy" : "Sell"))
        }

        components.append(coinName)

        let change = transaction.holding_net_change ?? 0
        let changeAmount = abs(change).formatCurrency(
            threshold: FormattingThreshold.none,
            currency: accessibleHoldingsCurrency(),
            accessible: true
        )
        if change > 0 {
            components.append(Localization.format("Change up %@", changeAmount))
        } else if change < 0 {
            components.append(Localization.format("Change down %@", changeAmount))
        } else {
            components.append(Localization.format("Change %@", changeAmount))
        }

        let balance = transaction.holding_balance ?? 0
        components.append(
            Localization.format(
                "Balance: %@",
                balance.formatCurrency(threshold: FormattingThreshold.none, currency: accessibleHoldingsCurrency(), accessible: true)
            )
        )

        return components.joined(separator: ". ")
    }
}
