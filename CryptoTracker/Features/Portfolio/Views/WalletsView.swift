//
//  TransactionsView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/29/25.
//

import SwiftUI

struct WalletsView: View {
    let portfolio: [Pie]?
    let prices: [Cryptocurrency]
    let hideData: Bool
    let showTransactionDetails: (any PortfolioEvent) -> Void

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            if let portfolio = portfolio.map({ $0.allWallets }), portfolio.isEmpty {
                EmptyContent(
                    title: Localization.string("No wallets yet"),
                    subTitle: Localization.string("Tap the + button to import a wallet into your portfolio.")
                )
                .frame(maxWidth: .infinity)
                .padding(
                    EdgeInsets(
                        top: 40,
                        leading: 32,
                        bottom: 0,
                        trailing: 32
                    )
                )
            } else {
                transactionsView
            }
        }
        .padding(
            EdgeInsets(
                top: 32,
                leading: 16,
                bottom: 82,
                trailing: 16
            )
        )
    }
    
    @ViewBuilder
    private var transactionsView: some View {
        let walletImports = portfolio.map({ $0.allWallets })?.sorted(by: { $0.date > $1.date }) ?? []
        
        ForEach(Array(walletImports.enumerated()), id: \.element) { index, walletImport in
            let coin = portfolio?.pie(containing: walletImport)?.data

            PortfolioImportView(
                coin: coin,
                walletImport: walletImport,
                prices: prices,
                hideData: hideData,
                index: index,
                totalCount: walletImports.count,
                showTransactionDetails: {
                    showTransactionDetails(walletImport)
                }
            )
        }
    }
}
