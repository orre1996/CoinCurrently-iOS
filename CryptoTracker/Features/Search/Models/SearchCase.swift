//
//  SearchCase.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-22.
//

import Foundation

enum SearchCase: String, Codable {
    case onlyCoins = ""
    case coins = "Coins"
    case nfts = "NFTs"
    case categories = "Sectors"
    case exchanges = "Exchanges"
    
    var accessibilityItemType: String {
        switch self {
        case .onlyCoins, .coins:
            return "Coin"
        case .nfts:
            return "NFT"
        case .categories:
            return "Sector"
        case .exchanges:
            return "Exchange"
        }
    }
}

enum SearchScreenCase: Codable, Equatable, Hashable {
    case search(list: SearchCase)
    case transaction(transactionType: NewTransactionType)
    case fixedList(list: [Toplist])
    
    var title: String {
        switch self {
        case .search(let list):
            switch list {
            case .onlyCoins, .coins:
                "Select Coin"
            case .nfts:
                "Select NFT"
            case .categories:
                "Select Sector"
            case .exchanges:
                "Select Exchange"
            }
        case .transaction(_):
            "Select Coin"
        case .fixedList(_):
            "Select Coin"
        }
    }
    
    var textfieldPlaceholder: String {
        switch self {
        case .search(let list):
            switch list {
            case .onlyCoins, .coins:
                "e.g. BTC or Ethereum"
            case .nfts:
                "e.g. CryptoPunks"
            case .categories:
                "e.g. Layer 1"
            case .exchanges:
                "e.g. Coinbase"
            }
        case .transaction(_):
            "e.g. BTC or Ethereum"
        case .fixedList(_):
            "e.g. BTC or Ethereum"
        }
    }
    
    var coins: [Toplist] {
        switch self {
        case .fixedList(let list):
            return list
        default:
            return []
        }
    }
}
