//
//  NFTTicker.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2/4/26.
//

import Foundation

struct NFTTickerResponse: Codable {
    let tickers: [NFTTicker]
}

struct NFTTicker: Codable, Hashable {
    let floor_price_in_native_currency: Double?
    let h24_volume_in_native_currency: Double?
    let nativeCurrency: String?
    let native_currency_symbol: String?
    let updated_at: String?
    let nft_marketplace_id: String?
    let name: String?
    let image: String?
    let nft_collection_url: String?
}
