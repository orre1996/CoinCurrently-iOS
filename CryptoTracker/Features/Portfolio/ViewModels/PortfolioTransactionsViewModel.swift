//
//  PortfolioTransactionsViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/2/26.
//

import Foundation

@MainActor
@Observable
final class PortfolioTransactionsViewModel {
    var groupedTransactions: [Date: [any PortfolioEvent]] = [:]
    var typeFilters: [NewTransactionType] = []
    var dateFilter: DateOption = .all
    var coinFilters: [Toplist] = []

    func setGroupTransactions(portfolio: [Pie]?) async {
        let typeFilters = self.typeFilters
        let dateFilter = self.dateFilter
        let coinFilters = self.coinFilters

        groupedTransactions = await Task.detached(priority: .userInitiated) {
            portfolio?.groupedTransactions(
                types: typeFilters,
                on: dateFilter,
                coinNames: coinFilters
            ) ?? [:]
        }.value
    }
}
