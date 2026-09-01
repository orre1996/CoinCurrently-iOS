//
//  ExchangePrices.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-22.
//

import Foundation

struct ExchangePriceModel: Codable {
    var price: Double?
    let timestamp: Double?
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        timestamp = try container.decodeIfPresent(Double.self)

        if let price = try container.decodeIfPresent(String.self), let doublePrice = Double(price) {
            self.price = Double(doublePrice)
        }
    }
}
