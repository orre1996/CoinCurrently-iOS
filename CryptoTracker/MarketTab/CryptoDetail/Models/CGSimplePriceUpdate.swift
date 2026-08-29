//
//  CGSimplePriceUpdate.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-07-18.
//

import Foundation

/// CoinGecko CGSimplePrice websocket payload.
/// https://docs.coingecko.com/websocket/cgsimpleprice
struct CGSimplePriceUpdate: Codable, Equatable {
    let channelType: String?
    let coinId: String?
    let vsCurrency: String?
    let price: Double?
    let priceChangePercentage24h: Double?
    let marketCap: Double?
    let volume24h: Double?
    let lastUpdatedAt: Int?

    enum CodingKeys: String, CodingKey {
        case channelType = "c"
        case coinId = "i"
        case vsCurrency = "vs"
        case price = "p"
        case priceChangePercentage24h = "pp"
        case marketCap = "m"
        case volume24h = "v"
        case lastUpdatedAt = "t"
    }

    func apply(to currency: CurrencyDataModel) -> CurrencyDataModel {
        guard let coinId, let currencyCode = vsCurrency?.lowercased() else {
            return currency
        }

        var updated = currency
        var marketData = updated.market_data ?? MarketData()

        if let price {
            var currentPrice = marketData.current_price ?? [:]
            currentPrice[currencyCode] = price
            marketData.current_price = currentPrice
        }

        if let marketCap {
            var caps = marketData.market_cap ?? [:]
            caps[currencyCode] = marketCap
            marketData.market_cap = caps
        }

        if let volume24h {
            var volume = marketData.total_volume ?? [:]
            volume[currencyCode] = volume24h
            marketData.total_volume = volume
        }

        if let priceChangePercentage24h {
            marketData.price_change_percentage_24h = priceChangePercentage24h
        }

        updated.id = updated.id ?? coinId
        updated.market_data = marketData
        return updated
    }
}
