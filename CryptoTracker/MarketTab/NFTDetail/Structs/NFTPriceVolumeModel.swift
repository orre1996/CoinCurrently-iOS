//
//  NFTPriceVolumeModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-10-10.
//

import Foundation

struct NFTPriceVolumeModel: Codable {
    var floor_price_usd: [NftDataPoint]? = nil
    var floor_price_native: [NftDataPoint]? = nil
    var h24_volume_usd: [NftDataPoint]? = nil
    var h24_volume_native: [NftDataPoint]? = nil
    var market_cap_usd: [NftDataPoint]? = nil
    var market_cap_native: [NftDataPoint]? = nil
}

struct NftDataPoint: Codable, Equatable {
    let timestamp: Double?
    var price: Double?

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        timestamp = try container.decodeIfPresent(Double.self)
    
        if let doubleValue = try? container.decode(Double.self) {
            self.price = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            self.price = Double(stringValue)
        }
    }
}
