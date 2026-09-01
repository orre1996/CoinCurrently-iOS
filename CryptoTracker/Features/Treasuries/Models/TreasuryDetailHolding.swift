//
//  TreasuryDetailHolding.swift
//  CoinCurrently
//

import Foundation

struct TreasuryDetailHolding: Codable, Equatable, Hashable {
    let coin_id: String?
    let amount: Double?
    let percentage_of_total_supply: Double?
    let amount_per_share: Double?
    let entity_value_usd_percentage: Double?
    let current_value_usd: Double?
    let total_entry_value_usd: Double?
    let average_entry_value_usd: Double?
    let unrealized_pnl: Double?
    let holding_amount_change: TreasuryHoldingPeriodChange?
    let holding_change_percentage: TreasuryHoldingPeriodChange?
}

struct TreasuryHoldingPeriodChange: Codable, Equatable, Hashable {
    let period_7d: Double?
    let period_14d: Double?
    let period_30d: Double?
    let period_90d: Double?
    let period_1y: Double?
    let ytd: Double?

    enum CodingKeys: String, CodingKey {
        case period_7d = "7d"
        case period_14d = "14d"
        case period_30d = "30d"
        case period_90d = "90d"
        case period_1y = "1y"
        case ytd
    }
}
