//
//  PortfolioEventWrapper.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 10/17/25.
//

import Foundation

enum PortfolioEventWrapper: Codable, Identifiable, Equatable, Hashable {
    case transaction(PortfolioTransaction)
    case swap(PortfolioSwapTransaction)
    case walletImport(AddressImport, [Cryptocurrency]?)

    var id: UUID {
        switch self {
        case .transaction(let tx):
            return tx.id
        case .swap(let swap):
            return swap.id
        case .walletImport(let walletImport, _):
            return walletImport.id
        }
    }
}
