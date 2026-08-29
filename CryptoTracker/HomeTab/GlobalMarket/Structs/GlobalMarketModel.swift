//
//  GlobalMarketModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-02-11.
//

import Foundation
import SwiftUI

struct GlobalMarketModel: Codable, Equatable {
    var data: GlobalMarketData?
}

struct GlobalMarketData: Codable, Equatable {
    let active_cryptocurrencies: Int
    let total_market_cap: [String: Double]?
    let total_volume: [String: Double]?
    let market_cap_percentage: [String: Double]?
    let market_cap_change_percentage_24h_usd: Double
    let markets: Int
    
    // Manually added
    var percentages: [Percentages]? = []
    
    private enum CodingKeys: String, CodingKey {
      case active_cryptocurrencies
      case total_market_cap
      case total_volume
      case market_cap_percentage
      case market_cap_change_percentage_24h_usd
      case markets
      case percentages
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        active_cryptocurrencies = try values.decode(Int.self, forKey: .active_cryptocurrencies)
        total_market_cap = try values.decode([String: Double]?.self, forKey: .total_market_cap)
        total_volume = try values.decode([String: Double]?.self, forKey: .total_volume)
        market_cap_percentage = try values.decode([String: Double].self, forKey: .market_cap_percentage)
        market_cap_change_percentage_24h_usd = try values.decode(Double.self, forKey: .market_cap_change_percentage_24h_usd)
        markets = try values.decode(Int.self, forKey: .markets)
        percentages = try values.decodeIfPresent([Percentages].self, forKey: .percentages)

        if percentages?.isEmpty ?? true {
            var percentages = [Percentages]()
            market_cap_percentage?.sorted(by: { $0.value > $1.value })
                .prefix(5)
                .filter({ $0.0.uppercased() != "USsDC" && $0.0.uppercased() != "UsSDT" })
                .forEach({ market in
                    let color = percentages.first(where: { $0.symbol == market.key })?.color
                    let image = percentages.first(where: { $0.symbol == market.key })?.image
                    percentages.append(Percentages(symbol: market.key, percentage: market.value / 100, color: color, image: image))
                })
            
            percentages = percentages.sorted(by: { $0.percentage > $1.percentage })
            
            let restPercent = 1 - (percentages.map({ $0.percentage }).reduce(0.0, +) )
            
            percentages.append(
                Percentages(
                    symbol: "OTHER",
                    percentage: restPercent,
                    color: nil
                )
            )
            
            self.percentages = percentages
        }
    }
}

struct Percentages: Codable, Equatable, Hashable {
    var symbol: String
    var percentage: Double
    var color: String? = nil
    var image: String? = nil
}
