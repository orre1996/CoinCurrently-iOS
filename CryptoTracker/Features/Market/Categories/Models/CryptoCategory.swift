//
//  CryptoCategory.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-10-28.
//

import Foundation

struct CryptoCategory: Codable, Equatable, Hashable {
    var id: String? = nil
    var name: String? = nil
    var market_cap: Double? = nil
    var market_cap_change_24h: Double? = nil
    var content: String? = nil
    var top_3_coins: [String]? = nil
    var volume_24h: Double? = nil
    var updated_at: String? = nil
}
