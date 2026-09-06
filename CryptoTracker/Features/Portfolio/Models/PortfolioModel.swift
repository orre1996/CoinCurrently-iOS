//
//  PortfolioModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/22/25.
//

import Foundation

struct PortfolioModel: Codable {
    let id: String
    let transactions: [PortfolioTransaction]
    let swaps: [PortfolioSwapTransaction]
    let imports: [AddressImport]
}

struct PortfolioExportModel: Codable {
    let coinId: String
    let transactions: [PortfolioExportTransaction]
    let swaps: [PortfolioExportSwap]
    let imports: [PortfolioExportImport]
}

struct PortfolioExportTransaction: Codable {
    let date: Date
    let amount: Double
    let pricePerCoin: Double?
    let fee: Double
    let note: String
    let transactionType: PortfolioTransactionType
    let address: String?
    let currency: String
    
    init(_ transaction: PortfolioTransaction) {
        date = transaction.date
        amount = transaction.amount
        pricePerCoin = transaction.pricePerCoin
        fee = transaction.fee
        note = transaction.note
        transactionType = transaction.transactionType
        address = transaction.address
        currency = transaction.currency
    }
}

struct PortfolioExportSwap: Codable {
    let date: Date
    let selectedCurrency: String
    let fromCurrencyId: String
    let fromCurrencySymbol: String
    let fromAmount: Double
    let fromUnitPrice: Double
    let toCurrencyId: String
    let toCurrencySymbol: String
    let toAmount: Double
    let toUnitPrice: Double
    let fee: Double
    let note: String
    
    init(_ swap: PortfolioSwapTransaction) {
        date = swap.date
        selectedCurrency = swap.selectedCurrency
        fromCurrencyId = swap.fromCurrencyId
        fromCurrencySymbol = swap.fromCurrencySymbol
        fromAmount = swap.fromAmount
        fromUnitPrice = swap.fromUnitPrice
        toCurrencyId = swap.toCurrencyId
        toCurrencySymbol = swap.toCurrencySymbol
        toAmount = swap.toAmount
        toUnitPrice = swap.toUnitPrice
        fee = swap.fee
        note = swap.note
    }
}

struct PortfolioExportImport: Codable {
    let date: Date
    let walletName: String?
    let coinId: String?
    let address: String
    let balance: String
    let tokenInfos: [TokenInfo]?
    let blockChain: Chain
    
    init(_ importEvent: AddressImport) {
        date = importEvent.date
        walletName = importEvent.walletName
        coinId = importEvent.coinId
        address = importEvent.address
        balance = importEvent.balance
        tokenInfos = importEvent.tokenInfos
        blockChain = importEvent.blockChain
    }
}
