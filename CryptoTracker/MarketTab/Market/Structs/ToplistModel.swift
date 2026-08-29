//
//  File.swift
//  Cryptocurrently
//
//  Created by Oscar Berggren on 2020-11-12.
//

import Foundation
import SwiftUI

struct Toplist: Codable, Identifiable, Equatable, Hashable {
    var id: String? = nil
    var symbol: String? = nil
    var name: String? = nil
    var image: String? = nil
    var current_price: Double? = nil
    var market_cap_rank: Int? = nil
    var sparkline_in_7d: Sparkline?
    var price_change_percentage_1h_in_currency: Double? = nil
    var price_change_percentage_24h_in_currency: Double? = nil
    var price_change_percentage_7d_in_currency: Double? = nil
    var price_change_percentage_30d_in_currency: Double? = nil
    var total_volume: Double? = nil
    var market_cap: Double? = nil
    
    func getPriceChange(selectedChangeOption: PriceChange) -> Double {
        switch selectedChangeOption {
        case .oneHour:
            return price_change_percentage_1h_in_currency ?? 0.0
        case .oneDay:
            return price_change_percentage_24h_in_currency ?? 0.0
        case .sevenDays:
            return price_change_percentage_7d_in_currency ?? 0.0
        case .oneMonth:
            return price_change_percentage_30d_in_currency ?? 0.0
        }
    }
    
    func getSortOption(
        priceChange: PriceChange
    ) -> Double {
        switch priceChange {
        case .oneHour:
            return price_change_percentage_1h_in_currency ?? 0
        case .oneDay:
            return price_change_percentage_24h_in_currency ?? 0
        case .sevenDays:
            return price_change_percentage_7d_in_currency ?? 0
        case .oneMonth:
            return price_change_percentage_30d_in_currency ?? 0
        }
    }
    
    var toCryptoDetail: CurrencyDataModel {
        let selectedCurrency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        return CurrencyDataModel(
            id: id,
            symbol: symbol,
            name: name,
            image: Logo(thumb: image, small: image, large: image),
            market_cap_rank: market_cap_rank,
            market_data: MarketData(
                current_price: current_price == nil ? [:] : [selectedCurrency.code.lowercased(): current_price ?? 0],
                price_change_percentage_24h: price_change_percentage_24h_in_currency,
                price_change_percentage_7d: price_change_percentage_7d_in_currency,
                price_change_percentage_30d: price_change_percentage_30d_in_currency),
            description: nil
        )
    }
    
    var toNFTDetail: NFTToplist {
        return NFTToplist(
            id: id,
            name: name,
            image: Logo(thumb: image, small: image, large: image),
        )
    }
    
    var toExchange: Exchange {
        return Exchange(
            id: id,
            name: name,
            image: image
        )
    }
    
    var toCategory: CryptoCategory {
        return CryptoCategory(
            id: id,
            name: name
        )
    }
}

struct Sparkline: Codable, Hashable, Equatable {
    var price: [Double]
}

extension Array where Element == Toplist {
    func getSortedToplist(sortOption: SortOption, priceChange: PriceChange) -> [Toplist] {
        switch sortOption {
        case .priceChangeDesc:
            return self.sorted(by: { $0.getSortOption(priceChange: priceChange) > $1.getSortOption(priceChange: priceChange) })
        case .priceChangeAsc:
            return self.sorted(by: { $0.getSortOption(priceChange: priceChange) < $1.getSortOption(priceChange: priceChange) })
        default:
            return self
        }
    }
}
