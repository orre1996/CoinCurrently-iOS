//
//  NFTToplist.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-09-29.
//

import Foundation

struct NFTToplist: Codable, Hashable {
    var id: String? = nil
    var contract_address: String? = nil
    var asset_platform_id: String? = nil
    var name: String? = nil
    var symbol: String? = nil
    var image: Logo? = nil
    var description: String? = nil
    var native_currency: String? = nil
    var native_currency_symbol: String? = nil
    var floor_price: FloorPrice? = nil
    var market_cap: FloorPrice? = nil
    var volume_24h: FloorPrice? = nil
    var market_cap_rank: Int? = nil
    var floor_price_in_usd_24h_percentage_change: Double? = nil
    var floor_price_24h_percentage_change: FloorPrice? = nil
    var market_cap_24h_percentage_change: FloorPrice? = nil
    var volume_24h_percentage_change: FloorPrice? = nil
    var number_of_unique_addresses: Int? = nil
    var number_of_unique_addresses_24h_percentage_change: Double? = nil
    var volume_in_usd_24h_percentage_change: Double? = nil
    var total_supply: Int? = nil
    var one_day_sales: Int? = nil
    var one_day_sales_24h_percentage_change: Double? = nil
    var one_day_average_sale_price: Double? = nil
    var one_day_average_sale_price_24h_percentage_change: Double? = nil
}

struct FloorPrice: Codable, Hashable {
    let native_currency: Double?
    let usd: Double?
    
    func getSelectedPrice(isFiatSelected: Bool, multiplier: Double?) -> Double? {
        return isFiatSelected ? (usd ?? 1) * (multiplier ?? 1) : native_currency
    }
}

struct FloorPriceDate: Codable, Hashable {
    let native_currency: String?
    let usd: String?
}

extension NFTToplist {
    var toNFTDetail: NFTDetail {
        return NFTDetail(
            id: id,
            contract_address: contract_address,
            asset_platform_id: asset_platform_id,
            name: name,
            symbol: symbol,
            image: image,
            banner_image: nil,
            description: description,
            native_currency: native_currency,
            native_currency_symbol: native_currency_symbol,
            floor_price: floor_price,
            market_cap: market_cap,
            volume_24h: volume_24h,
            market_cap_rank: market_cap_rank,
            floor_price_in_usd_24h_percentage_change: floor_price_in_usd_24h_percentage_change,
            floor_price_24h_percentage_change: floor_price_24h_percentage_change,
            market_cap_24h_percentage_change: market_cap_24h_percentage_change,
            volume_24h_percentage_change: volume_24h_percentage_change,
            number_of_unique_addresses: number_of_unique_addresses != nil ? Double(number_of_unique_addresses!) : nil,
            number_of_unique_addresses_24h_percentage_change: number_of_unique_addresses_24h_percentage_change,
            volume_in_usd_24h_percentage_change: volume_in_usd_24h_percentage_change,
            total_supply: total_supply != nil ? Double(total_supply!) : nil,
            one_day_sales: one_day_sales,
            one_day_sales_24h_percentage_change: one_day_sales_24h_percentage_change,
            one_day_average_sale_price: one_day_average_sale_price,
            one_day_average_sale_price_24h_percentage_change: one_day_average_sale_price_24h_percentage_change,
            links: nil,
            floor_price_7d_percentage_change: nil,
            floor_price_14d_percentage_change: nil,
            floor_price_30d_percentage_change: nil,
            floor_price_60d_percentage_change: nil,
            floor_price_1y_percentage_change: nil,
            explorers: nil,
            user_favorites_count: nil,
            ath: nil,
            ath_change_percentage: nil,
            ath_date: nil
        )
    }
}
