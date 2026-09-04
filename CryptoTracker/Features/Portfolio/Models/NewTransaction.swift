//
//  NewTransaction.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/22/25.
//

import Foundation
import SwiftUI

protocol PortfolioEvent: Identifiable, Codable, Hashable, Equatable, Sendable {
    var id: UUID { get }
    var date: Date { get }
}

struct NewTransaction: PortfolioEvent {
    var id: UUID = UUID()
    var date: Date = Date()
    var amount: Double
    var pricePerCoin: Double?
    var fee: Double
    var note: String
    var transactionType: NewTransactionType
    var address: String?
    var currency: String
    
    func getProfitPercent(currentPrice: Double?) -> Double? {
        if pricePerCoin == nil { return nil }
        
        let originalCost = amount * (pricePerCoin ?? 1)
        
        let currentValue = amount * (currentPrice ?? 0)
        return (currentValue / originalCost - 1) * 100
    }
    
    func getProfitValue(currentPrice: Double?) -> Double? {
        if pricePerCoin == nil { return nil }
        
        let profitPercent = getProfitPercent(currentPrice: currentPrice) ?? 0
        return ((profitPercent / 100)) * (pricePerCoin ?? 0) * amount
    }
    
    func toCleanTransaction(isTransferType: Bool) -> CleanTransactionModel {
        let selectedCurrency = CurrencyModel.allCurrencies.first(where: { $0.code.lowercased() == currency.lowercased() })
        let value = (amount * (pricePerCoin ?? 0)) + (fee)
        
        return CleanTransactionModel(
            date: date.longDateTime,
            amount: "\(amount)",
            pricePerCoin: isTransferType ? nil : pricePerCoin?.formatted(style: .exact(currency: selectedCurrency)),
            fee: isTransferType ? nil : fee.formatted(style: .exact(currency: selectedCurrency)),
            valueTraded:  isTransferType ? nil : value == 0 ? nil : value.formatted(style: .exact(currency: selectedCurrency)),
            currency: isTransferType ? nil : currency,
            note: note
        )
    }

    var feeValue: Double {
        return isAddOrInTransferTransaction ? fee : -fee
    }
    
    var totalSpent: Double {
        return (pricePerCoin ?? 0) * amount + feeValue
    }
    
    var getTransactionImage: Image {
        switch transactionType {
        case .buy:
            Image.plus
        case .sell:
            Image.minus
        case .swap:
            Image.arrowRight
        case .transferIn:
            Image.arrowRight
        case .transferOut:
            Image.arrowLeft
        case .importAddress:
            Image.arrowRight
        }
    }
    
    var transactionText: String {
        switch transactionType {
        case .buy:
            "Bought"
        case .sell:
            "Sold"
        case .swap:
            "Swapped"
        case .transferIn:
            "Received"
        case .transferOut:
            "Sent"
        case .importAddress:
            "Imported"
        }
    }
    
#if IS_APP
    var transactionTypeTextColor: Color {
        switch transactionType {
        case .buy, .importAddress, .transferIn:
            return .trendUp
        case .sell, .transferOut:
            return .trendDown
        case .swap:
            return .onSurfaceDim
        }
    }
#endif
    
    var isAddOrInTransferTransaction: Bool {
        switch transactionType {
        case .buy, .importAddress, .transferIn, .swap:
            return true
        case .sell, .transferOut:
            return false
        }
    }
    
    var getTransactionPrefixSign: String {
        return isAddOrInTransferTransaction ? "+" : "-"
    }
}
