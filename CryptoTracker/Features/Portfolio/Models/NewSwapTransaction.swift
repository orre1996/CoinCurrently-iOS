//
//  NewSwapTransaction.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 10/16/25.
//

import SwiftUI

struct NewSwapTransaction: PortfolioEvent {
    var id: UUID = UUID()
    var date: Date = Date()
    var selectedCurrency: String
    
    var fromCurrencyId: String
    var fromCurrencySymbol: String
    var fromAmount: Double
    var fromUnitPrice: Double
    
    var toCurrencyId: String
    var toCurrencySymbol: String
    var toAmount: Double
    var toUnitPrice: Double
    
    var fee: Double
    var note: String
}

extension NewSwapTransaction {
    var sellTransaction: NewTransaction {
        NewTransaction(
            date: date,
            amount: fromAmount,
            pricePerCoin: fromUnitPrice,
            fee: fee,
            note: note,
            transactionType: .sell,
            currency: selectedCurrency
        )
    }
    
    var buyTransaction: NewTransaction {
        return NewTransaction(
            date: date,
            amount: toAmount,
            pricePerCoin: toUnitPrice,
            fee: 0,
            note: note,
            transactionType: .buy,
            currency: selectedCurrency
        )
    }
}
