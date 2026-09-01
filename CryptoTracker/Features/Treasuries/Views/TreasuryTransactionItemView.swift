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
                NewShimmeringText(
                    text: formattedDate,
                    isDownloading: transaction == nil
                )
                .font(.satoshiBold(14))
            }
            .font(.satoshiMedium(16))
            .foregroundStyle(Color.onSurface)

            HStack(spacing: 4) {
                ShimmeringImage(
                    imageUrl: coin?.image,
                    downloading: transaction != nil && coin == nil,
                    size: 20 * min(scale, 1.5)
                )

                NewShimmeringText(
                    text: coinName,
                    isDownloading: transaction == nil
                )
                .font(.satoshiBold(16))
                .foregroundStyle(Color.onSurface)
            }
            .padding(.trailing, 12)

            VStack(alignment: .trailing, spacing: 0) {
                NewShimmeringText(
                    text: balanceText,
                    isDownloading: transaction == nil
                )
                .font(.satoshiBold(16))
                .foregroundStyle(Color.onSurface)

                NewShimmeringText(
                    text: netChangeText,
                    isDownloading: transaction == nil
                )
                .font(.satoshiBold(12))
                .foregroundStyle(netChangeColor)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
    }

    private var formattedDate: String {
        guard let timestamp = transaction?.date else { return "000000" }
        return Date(timeIntervalSince1970: timestamp / 1000).mediumDate
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

    private var accessibilityLabelText: String {
        guard transaction != nil else { return "Loading transaction" }

        var components = [formattedDate, coinName]
        components.append("Balance \(balanceText)")
        components.append("Change \(netChangeText)")
        return components.joined(separator: ". ")
    }
}
