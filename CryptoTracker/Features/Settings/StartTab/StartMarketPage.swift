//
//  StartMarketPage.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-01-09.
//

import Foundation

enum StartMarketPage: String, Codable {
    case currencies = "Currencies"
    case nfts = "NFTs"
    case categories = "Categories"
    case exchanges = "Exchanges"
    case derivatives = "Derivatives"
    
    var getPage: Int {
        switch self {
            case .currencies:
                return 0
            
            case .nfts:
                return 1
            
            case .categories:
                return 2
            
            case .exchanges:
                return 3
            
            case .derivatives:
                return 4
        }
    }
}
