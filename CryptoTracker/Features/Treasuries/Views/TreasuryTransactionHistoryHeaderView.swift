//
//  TreasuryTransactionHistoryHeaderView.swift
//  CoinCurrently
//

import SwiftUI

struct TreasuryTransactionHistoryHeaderView: View {
    var body: some View {
        HStack(spacing: 4) {
            MinimumTextSize(
                text: "Dec 31, 2025",
                alignment: .leading
            ) {
                Text(Localization.string("Date"))
                    .font(.satoshiMedium(14))
            }
            .font(.satoshiBold(16))

            Text(Localization.string("Coin"))

            Text(Localization.string("Balance"))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.satoshiMedium(14))
        .foregroundStyle(Color.onSurfaceDim)
        .padding(.bottom, 6)
        .accessibilityHidden(true)
    }
}
