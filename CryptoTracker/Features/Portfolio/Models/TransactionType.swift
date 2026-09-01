//
//  TransactionType.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-08-29.
//

import Foundation

enum TransactionType: Int {
    case transfer = 2
    case buy = 0
    case sell = 1
    case importAddress = 3
    
    var newRawValue: Int {
        switch self {
            case .transfer:
                return 3

            case .buy:
                return 1

            case .sell:
                return 2

            case .importAddress:
                return 0
        }
    }
}

enum TransferType: Int {
    case outType = 0
    case inType = 1
}
