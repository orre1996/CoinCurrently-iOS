//
//  NFTDetail.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2/3/26.
//

import Foundation
import SwiftUI

struct NFTDetail: Codable, Hashable {
    let id: String?
    var contract_address: String? = nil
    var asset_platform_id: String? = nil
    var name: String? = nil
    var symbol: String? = nil
    var image: Logo? = nil
    var banner_image: String? = nil
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
    var number_of_unique_addresses: Double? = nil
    var number_of_unique_addresses_24h_percentage_change: Double? = nil
    var volume_in_usd_24h_percentage_change: Double? = nil
    var total_supply: Double? = nil
    var one_day_sales: Int? = nil
    var one_day_sales_24h_percentage_change: Double? = nil
    var one_day_average_sale_price: Double? = nil
    var one_day_average_sale_price_24h_percentage_change: Double? = nil
    var links: NFTLinks? = nil
    var floor_price_7d_percentage_change: FloorPrice? = nil
    var floor_price_14d_percentage_change: FloorPrice? = nil
    var floor_price_30d_percentage_change: FloorPrice? = nil
    var floor_price_60d_percentage_change: FloorPrice? = nil
    var floor_price_1y_percentage_change: FloorPrice? = nil
    var explorers: [NFTExplorer]? = nil
    var user_favorites_count: Int? = nil
    var ath: FloorPrice? = nil
    var ath_change_percentage: FloorPrice? = nil
    var ath_date: FloorPriceDate? = nil
}

struct NFTLinks: Codable, Hashable {
    var homepage: String? = nil
    var twitter: String? = nil
    var discord: String? = nil
}

struct NFTExplorer: Codable, Hashable {
    var name: String? = nil
    var link: String? = nil
}

extension NFTDetail {
    var officialWebsites: [String] {
        guard let links = links, let homepage = links.homepage, !homepage.isEmpty else {
            return []
        }
        return [homepage]
    }
    
    var socialMediaUrls: [String] {
        var urls: [String] = []
        if let twitter = links?.twitter, !twitter.isEmpty {
            urls.append(twitter)
        }
        if let discord = links?.discord, !discord.isEmpty {
            urls.append(discord)
        }
        return urls
    }
    
    var socialMediaIcons: [Image] {
        var icons: [Image] = []
        if let twitter = links?.twitter, !twitter.isEmpty {
            icons.append(.x)
        }
        if let discord = links?.discord, !discord.isEmpty {
            icons.append(.discordLogo)
        }
        return icons
    }
    
    var explorerUrls: [String] {
        return explorers?.compactMap { $0.link }.filter { !$0.isEmpty } ?? []
    }
    
    var explorerIcons: [Image] {
        let count = explorerUrls.count
        return Array(repeating: Image.explorerLogo, count: count)
    }
    
    var isAllLinksEmpty: Bool {
        return description?.isEmpty ?? true &&
               officialWebsites.isEmpty &&
               socialMediaUrls.isEmpty &&
               explorerUrls.isEmpty
    }
}
