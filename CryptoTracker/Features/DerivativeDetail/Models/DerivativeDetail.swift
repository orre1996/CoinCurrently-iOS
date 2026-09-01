//
//  DerivativeDetail.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-10-26.
//

import Foundation

struct DerivativeDetail: Codable, Equatable, Hashable, Identifiable {
    var id: String { "\(symbol ?? "")-\(expired_at ?? 0)" }
    var symbol: String? = nil
    var base: String? = nil
    var target: String? = nil
    var coin_id: String? = nil
    var target_coin_id: String? = nil
    var trade_url: String? = nil
    var contract_type: String? = nil
    var last: Double? = nil
    var h24_percentage_change: Double? = nil
    var index: Double? = nil
    var index_basis_percentage: Double? = nil
    var bid_ask_spread: Double? = nil
    var funding_rate: Double? = nil
    var open_interest_usd: Double? = nil
    var h24_volume: Double? = nil
    var converted_volume: ConvertedLastString? = nil
    var converted_last: ConvertedLastString? = nil
    var last_traded: Double? = nil
    var expired_at: Double? = nil
}

struct ConvertedLastString: Codable, Equatable, Hashable {
    var btc: String? = nil
    var eth: String? = nil
    var usd: String? = nil
}
