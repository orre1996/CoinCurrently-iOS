//
//  ExchangeMarketItem.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-03-12.
//

import Foundation
import SwiftUI

/// A display model for exchange/market list items, used across Crypto, NFT, and Exchange detail screens.
struct ExchangeMarketItem: Identifiable, Hashable {
    let id: UUID
    let name: String?
    let imageUrl: String?
    let tradeUrl: String?
    let price: Double?
    let volume: Double?
    let priceCurrency: CurrencyModel

    init(
        id: UUID = UUID(),
        name: String?,
        imageUrl: String?,
        tradeUrl: String?,
        price: Double?,
        volume: Double? = nil,
        priceCurrency: CurrencyModel = CurrencyModel()
    ) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.tradeUrl = tradeUrl
        self.price = price
        self.volume = volume
        self.priceCurrency = priceCurrency
    }
}

// MARK: - Mapping from source types

extension ExchangeMarketItem {
    static func from(_ ticker: Ticker) -> ExchangeMarketItem {
        let imageUrl = ticker.trade_url.map { "https://www.google.com/s2/favicons?domain=\($0)" }
        return ExchangeMarketItem(
            name: ticker.market?.name,
            imageUrl: imageUrl,
            tradeUrl: ticker.trade_url,
            price: ticker.converted_last?[String.usd],
            volume: ticker.converted_volume?[String.usd],
            priceCurrency: CurrencyModel()
        )
    }

    static func from(_ ticker: NFTTicker) -> ExchangeMarketItem {
        let currency = CurrencyModel(
            currency: " \(ticker.native_currency_symbol?.uppercased() ?? "")",
            code: " \(ticker.native_currency_symbol?.uppercased() ?? "")",
            symbol: " \(ticker.native_currency_symbol?.uppercased() ?? "")",
            suffix: true
        )
        return ExchangeMarketItem(
            name: ticker.name,
            imageUrl: ticker.image,
            tradeUrl: ticker.nft_collection_url,
            price: ticker.floor_price_in_native_currency,
            volume: nil,
            priceCurrency: currency
        )
    }

    static func from(_ ticker: ExchangeTicker) -> ExchangeMarketItem {
        from(ticker, toplist: nil)
    }

    /// Creates an ExchangeMarketItem from ExchangeTicker, using toplist to resolve the base coin's image.
    static func from(_ ticker: ExchangeTicker, toplist: [Toplist]?) -> ExchangeMarketItem {
        let pairName: String? = {
            if let base = ticker.base, let target = ticker.target, !base.isEmpty || !target.isEmpty {
                return "\(base)/\(target)"
            }
            return ticker.market?.name
        }()
        let imageUrl: String? = {
            if let toplist {
                if let coinId = ticker.coin_id,
                   let match = toplist.first(where: { $0.id == coinId })?.image {
                    return match
                }
                if let base = ticker.base,
                   let match = toplist.first(where: { $0.symbol?.lowercased() == base.lowercased() })?.image {
                    return match
                }
                return nil
            }
            return ticker.trade_url.map { "https://www.google.com/s2/favicons?domain=\($0)" }
        }()
        return ExchangeMarketItem(
            name: pairName,
            imageUrl: imageUrl,
            tradeUrl: ticker.trade_url,
            price: ticker.converted_last?.usd ?? ticker.last,
            volume: ticker.converted_volume?.usd,
            priceCurrency: CurrencyModel()
        )
    }
}

extension Array where Element == ExchangeMarketItem {
    func sorted(by option: SortOption) -> [ExchangeMarketItem] {
        switch option {
        case .volumeDesc:
            return sorted { ($0.volume ?? 0) > ($1.volume ?? 0) }
        case .volumeAsc:
            return sorted { ($0.volume ?? 0) < ($1.volume ?? 0) }
        case .priceDesc:
            return sorted { ($0.price ?? 0) > ($1.price ?? 0) }
        case .priceAsc:
            return sorted { ($0.price ?? 0) < ($1.price ?? 0) }
        case .nameDesc:
            return sorted { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedDescending }
        case .nameAsc:
            return sorted { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }
        default:
            return sorted { ($0.volume ?? 0) > ($1.volume ?? 0) }
        }
    }
}
