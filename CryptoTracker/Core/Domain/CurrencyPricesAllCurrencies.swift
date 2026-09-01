//
//  Cryptocurrency.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-13.
//

import Foundation

struct CurrencyPricesAllCurrencies: Codable {
    let cryptocurrencies: [Cryptocurrency]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var tempCryptocurrencies = [Cryptocurrency]()
    
        for key in container.allKeys {
            let prices = try container.decode([String: Double].self, forKey: key)
            let cryptocurrency = Cryptocurrency(id: key.stringValue, prices: prices)
            tempCryptocurrencies.append(cryptocurrency)
        }
        
        cryptocurrencies = tempCryptocurrencies
    }
}

struct Cryptocurrency: Codable, Equatable, Hashable {
    let id: String
    var prices: [String: Double]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        prices = try container.decode([String: Double].self, forKey: .prices)
    }

    init(id: String, prices: [String: Double]) {
        self.id = id
        self.prices = prices
    }

    enum CodingKeys: CodingKey {
        case id
        case prices
    }
}
