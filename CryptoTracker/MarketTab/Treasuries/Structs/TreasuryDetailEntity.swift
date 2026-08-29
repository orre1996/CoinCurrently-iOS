//
//  TreasuryDetailEntity.swift
//  CoinCurrently
//

import Foundation

struct TreasuryDetailEntity: Codable, Equatable, Hashable {
    let name: String?
    let id: String?
    let type: String?
    let symbol: String?
    let country: String?
    let website_url: String?
    let twitter_screen_name: String?
    let total_treasury_value_usd: Double?
    let unrealized_pnl: Double?
    let m_nav: Double?
    let total_asset_value_per_share_usd: Double?
    let holdings: [TreasuryDetailHolding]?

    func copy(withId: String) -> TreasuryDetailEntity {
        TreasuryDetailEntity(
            name: name,
            id: withId,
            type: type,
            symbol: symbol,
            country: country,
            website_url: website_url,
            twitter_screen_name: twitter_screen_name,
            total_treasury_value_usd: total_treasury_value_usd,
            unrealized_pnl: unrealized_pnl,
            m_nav: m_nav,
            total_asset_value_per_share_usd: total_asset_value_per_share_usd,
            holdings: holdings
        )
    }
}
