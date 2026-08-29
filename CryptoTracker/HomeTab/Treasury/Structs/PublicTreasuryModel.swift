//
//  PublicTreasuryModel.swift
//  CoinCurrently
//

import Foundation

struct PublicTreasuryModel: Codable, Equatable {
    let total_holdings: Double?
    let total_value_usd: Double?
    let market_cap_dominance: Double?
    let companies: [PublicTreasuryHolder]?
    let governments: [PublicTreasuryHolder]?

    var holders: [PublicTreasuryHolder] {
        companies ?? governments ?? []
    }
}

struct PublicTreasuryHolder: Codable, Equatable, Hashable {
    let id: String?
    let name: String?
    let symbol: String?
    let country: String?
    let total_holdings: Double?
    let total_entry_value_usd: Double?
    let total_current_value_usd: Double?
    let percentage_of_total_supply: Double?
}

struct TreasuryListItem: Hashable {
    let holder: PublicTreasuryHolder
    let entity: TreasuryEntity
    let coinId: String
}

struct TreasuryEntityListItem: Codable, Equatable, Hashable {
    let id: String
    let symbol: String?
    let name: String
    let country: String?
}

extension PublicTreasuryHolder {
    func toTreasuryDetail(treasuryId: String, coinId: String) -> TreasuryDetailEntity {
        TreasuryDetailEntity(
            name: name,
            id: treasuryId,
            type: nil,
            symbol: symbol,
            country: country,
            website_url: nil,
            twitter_screen_name: nil,
            total_treasury_value_usd: total_current_value_usd,
            unrealized_pnl: nil,
            m_nav: nil,
            total_asset_value_per_share_usd: nil,
            holdings: [
                TreasuryDetailHolding(
                    coin_id: coinId,
                    amount: total_holdings,
                    percentage_of_total_supply: percentage_of_total_supply,
                    amount_per_share: nil,
                    entity_value_usd_percentage: nil,
                    current_value_usd: total_current_value_usd,
                    total_entry_value_usd: total_entry_value_usd,
                    average_entry_value_usd: nil,
                    unrealized_pnl: nil,
                    holding_amount_change: nil,
                    holding_change_percentage: nil
                )
            ]
        )
    }
}
