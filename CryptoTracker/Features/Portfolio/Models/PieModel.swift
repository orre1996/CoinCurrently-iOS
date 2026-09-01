//
//  PieModel.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2020-12-19.
//

import Foundation
import SwiftUI

struct Pie: Codable, Hashable, Equatable {
    let data: Toplist?
    var color: String? = nil
    var transactions: [NewTransaction] = []
    var swaps: [NewSwapTransaction] = []
    var imports: [AddressImport] = []
    
    var toPortfolioCurrencyModel: NewPortfolioModel? {
        data?.id.map {
            NewPortfolioModel(
                id: $0,
                transactions: transactions,
                swaps: swaps,
                imports: imports
            )
        }
    }
    
    var toPortfolioExportModel: PortfolioExportModel? {
        data?.id.map {
            PortfolioExportModel(
                coinId: $0,
                transactions: transactions.map(PortfolioExportTransaction.init),
                swaps: swaps.map(PortfolioExportSwap.init),
                imports: imports.map(PortfolioExportImport.init)
            )
        }
    }
    
    var oldestDate: Date? {
        let allDates =
        transactions.map { $0.date } +
        swaps.map { $0.date } +
        imports.map { $0.date }
        
        return allDates.min()
    }

    var shouldShow: Bool {
        let hasActivity =
            !transactions.isEmpty ||
            !swaps.isEmpty ||
            imports.contains { !$0.balance.isEmpty }
        
        let isCompletelyEmpty =
            transactions.isEmpty &&
            swaps.isEmpty &&
            imports.isEmpty
        
        return hasActivity || isCompletelyEmpty
    }
    
    /*func getUnrealizedProfitLossValue(
        prices: [String: Double]?,
        showCurrency: String = (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code.lowercased()
    ) -> Double? {
        var spent = transactions.ofType(.buy).reduce(0) { sum, tx in
            let multiplier = priceMultiplier(prices: prices, showCurrency: showCurrency, transactionCurrency: tx.currency)
            return sum + tx.amount * ((tx.pricePerCoin ?? 1) * multiplier)
        }
        
        spent += transactions.ofType(.transferIn).reduce(0) { sum, tx in
            let multiplier = priceMultiplier(prices: prices, showCurrency: showCurrency, transactionCurrency: tx.currency)
            return sum + tx.amount * ((prices?[showCurrency.lowercased()] ?? 0) * multiplier)
        }
        
        transactions.ofType(.sell).forEach {
            let multiplier = priceMultiplier(prices: prices, showCurrency: showCurrency, transactionCurrency: $0.currency)
            spent -= $0.amount * (($0.pricePerCoin ?? 1) * multiplier)
        }
        
        transactions.ofType(.transferOut).forEach {
            let multiplier = priceMultiplier(prices: prices, showCurrency: showCurrency, transactionCurrency: $0.currency)
            spent -= $0.amount * ((prices?[showCurrency.lowercased()] ?? 0) * multiplier)
        }
        
        spent += transactions.ofType(.importAddress).reduce(0) { sum, tx in
            let multiplier = priceMultiplier(prices: prices, showCurrency: showCurrency, transactionCurrency: tx.currency)
            return sum + tx.amount * ((prices?[showCurrency.lowercased()] ?? 0) * multiplier)
        }
        
        let currentValue = transactions.getAmount(withTransfers: true) * (prices?[showCurrency.lowercased()] ?? 1)
        return currentValue - spent
    }*/
    
    /*func toCleanPortfolioModel() -> CleanPortfolioModel {
        return CleanPortfolioModel(
            name: data?.name,
            buyTransactions: buyTransactions.isEmpty ? nil : buyTransactions.map({ $0.toCleanTransaction(isTransferType: false) }).sorted(by: { $0.date.localizedDescriptionDate ?? Date() < $1.date.localizedDescriptionDate ?? Date() }),
            sellTransactions: sellTransactions.isEmpty ? nil : sellTransactions.map({ $0.toCleanTransaction(isTransferType: false) }).sorted(by: { $0.date.localizedDescriptionDate ?? Date() < $1.date.localizedDescriptionDate ?? Date() }),
            depositTransactions: inTransferTransactions.isEmpty ? nil : inTransferTransactions.map({ $0.toCleanTransaction(isTransferType: true) }).sorted(by: { $0.date.localizedDescriptionDate ?? Date() < $1.date.localizedDescriptionDate ?? Date() }),
            withdrawalTransactions: outTransferTransactions.isEmpty ? nil : outTransferTransactions.map({ $0.toCleanTransaction(isTransferType: true) }).sorted(by: { $0.date.localizedDescriptionDate ?? Date() < $1.date.localizedDescriptionDate ?? Date() }),
            importTransactions: importTransactions.isEmpty ? nil : importTransactions.map({ $0.toCleanTransaction(isTransferType: false) }).sorted(by: { $0.date.localizedDescriptionDate ?? Date() < $1.date.localizedDescriptionDate ?? Date() })
        )
    }*/
}
