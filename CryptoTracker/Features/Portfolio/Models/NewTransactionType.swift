//
//  NewTransactionType.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 10/16/25.
//

import Foundation

enum NewTransactionType: String, Codable {
    case buy = "Bought"
    case sell = "Sold"
    case swap = "Swapped"
    case transferIn = "Deposited"
    case transferOut = "Withdrew"
    case importAddress = "Imported"
    
    var isTransfer: Bool {
        return self == .transferIn || self == .transferOut
    }
    
    var isAddTransfer: Bool {
        return self == .buy || self == .transferIn || self == .importAddress
    }
}
