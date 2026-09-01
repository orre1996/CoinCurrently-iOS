//
//  TransactionHistoryView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/24/26.
//

import SwiftUI

struct TreasuryTransactionHistoryView: View {
    let holdings: [Toplist]
    let selectedHoldingCoinId: String?
    let transactions: [TreasuryTransaction]?
    let showHoldingFilter: () -> Void

    private var filterButtonTitle: String {
        guard let selectedHoldingCoinId else { return "All Holdings" }

        return holdings.first(where: { $0.id == selectedHoldingCoinId })?.name
            ?? selectedHoldingCoinId.capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SecondaryButton(
                text: filterButtonTitle,
                accessibilityLabel: "Holding, currently selected: \(filterButtonTitle)",
                icon: .chevronDown,
                action: showHoldingFilter
            )
            .padding(.bottom, 24)

            TreasuryTransactionHistoryHeaderView()

            Group {
                if let transactions {
                    ForEach(Array(transactions.enumerated()), id: \.offset) { _, transaction in
                        TreasuryTransactionItemView(
                            transaction: transaction,
                            coin: coin(for: transaction.coin_id)
                        )
                    }
                } else {
                    ForEach(0..<6, id: \.self) { _ in
                        TreasuryTransactionItemView(
                            transaction: nil,
                            coin: nil
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func coin(for coinId: String?) -> Toplist? {
        guard let coinId else { return nil }
        return holdings.first(where: { $0.id == coinId })
    }
}
