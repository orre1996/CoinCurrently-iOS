//
//  Chain.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2/6/26.
//

import Foundation

enum Chain: String, CaseIterable, Codable {
    case btc
    case eth
    case sol
    case xrp
    case doge
    case token
    
    var id: String {
        switch self {
        case .btc:
            return "bitcoin"
        case .eth, .token:
            return "ethereum"
        case .sol:
            return "solana"
        case .xrp:
            return "ripple"
        case .doge:
            return "dogecoin"
        }
    }
}
