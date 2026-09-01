//
//  TrendingCoins.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-09-14.
//

import Foundation

struct TrendingItems: Codable {
    var coins: [TrendingCoin]?
    let nfts: [TrendingNFT]?
    let categories: [TrendingCategory]?
}

struct TrendingCoin: Codable {
    let item: CoinItem?
}

struct CoinItem: Codable {
    let id: String?
    let coin_id: Int?
    let name: String?
    let symbol: String?
    let market_cap_rank: Int?
    let thumb: String?
    let small: String?
    let large: String?
    let slug: String?
    let price_btc: Double?
    let score: Int?
    let data: CoinData?
    
    var toToplist: Toplist {
        return Toplist(
            id: id,
            symbol: symbol,
            name: name,
            image: large,
            market_cap_rank: market_cap_rank
        )
    }
}

struct CoinData: Codable {
    let price: Double?
    let price_btc: String?
    let price_change_percentage_24h: [String: Double]?
    let market_cap: String?
    let market_cap_btc: String?
    let total_volume: String?
    let total_volume_btc: String?
    let sparkline: String?
    let content: CoinContent?
}

struct CoinContent: Codable {
    let title: String?
    let description: String?
}

struct TrendingNFT: Codable {
    let id: String?
    let name: String?
    let symbol: String?
    let thumb: String?
    let nft_contract_id: Int?
    let native_currency_symbol: String?
    let floor_price_in_native_currency: Double?
    let floor_price_24h_percentage_change: Double?
    let data: NFTData?
    
    var toToplist: Toplist {
        return Toplist(
            id: id,
            symbol: symbol,
            name: name,
            image: thumb
        )
    }
}

struct NFTData: Codable {
    let floor_price: String?
    let floor_price_in_usd_24h_percentage_change: String?
    let h24_volume: String?
    let h24_average_sale_price: String?
    let sparkline: String?
    let content: NFTContent?
}

struct NFTContent: Codable {
    let title: String?
    let description: String?
}

struct TrendingCategory: Codable {
    let id: Int?
    let name: String?
    let market_cap_1h_change: Double?
    let slug: String?
    let coins_count: String?
    let data: CategoryData?
    
    var toToplist: Toplist {
        return Toplist(
            id: "\(id ?? 0)",
            name: name
        )
    }
}

struct CategoryData: Codable {
    let market_cap: Double?
    let market_cap_btc: Double?
    let total_volume: Double?
    let total_volume_btc: Double?
    let market_cap_change_percentage_24h: [String: Double]?
    let sparkline: String?
}
