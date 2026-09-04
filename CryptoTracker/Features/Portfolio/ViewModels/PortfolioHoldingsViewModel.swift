//
//  PortfolioHoldingsViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/2/26.
//

import Foundation

@MainActor
@Observable
final class PortfolioHoldingsViewModel {
    private(set) var totalValue: Double?
    private(set) var profitLossPercent: Double?
    private(set) var profitLossValue: Double?
    private(set) var portfolioPieSlices: [PortfolioPieSlice] = []
    private(set) var coinFilterList: [Toplist] = []

    func recalculate(
        portfolio: [Pie]?,
        allPrices: [Cryptocurrency],
        pricesById: [String: [String: Double]],
        amountsById: [String: Double],
        currencyCode: String,
        profitLossCurrencyCode: String
    ) {
        coinFilterList = portfolio?
            .filter { !($0.transactions.isEmpty && $0.swaps.isEmpty && $0.imports.isEmpty) }
            .compactMap { $0.data }
            ?? []

        guard let portfolio else {
            totalValue = nil
            profitLossPercent = nil
            profitLossValue = nil
            portfolioPieSlices = []
            return
        }

        totalValue = portfolio.reduce(0.0) { sum, pie in
            guard let id = pie.data?.id else { return sum }
            let lastPrice = pie.data?.holdingPrice(
                vsCurrencyPrices: pricesById[id],
                currencyCode: currencyCode
            ) ?? 0
            let amount = amountsById[id] ?? 0
            return sum + lastPrice * amount
        }

        profitLossPercent = portfolio.getProfitLossPercent(
            coinPrices: allPrices,
            showCurrency: profitLossCurrencyCode
        )
        profitLossValue = portfolio.getProfitLossValue(
            coinPrices: allPrices,
            showCurrency: profitLossCurrencyCode
        )
        portfolioPieSlices = PortfolioPieChartLayout.slices(
            portfolio: portfolio,
            totalValue: totalValue,
            pricesById: pricesById,
            amountsById: amountsById,
            currencyCode: currencyCode
        )
    }
}
