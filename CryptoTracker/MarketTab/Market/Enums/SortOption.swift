//
//  SortOption.swift
//  CoinCurrently
//
//  Unified sort option for toplist, NFTs, categories, and exchanges.
//

import Foundation

enum SortOption: String, CaseIterable, Codable {
    // Shared
    case mktCapDesc
    case mktCapAsc
    case nameDesc
    case nameAsc
    // Toplist
    case priceChangeDesc
    case priceChangeAsc
    case volumeDesc
    case volumeAsc
    // Exchanges
    case trustScoreDesc
    case trustScoreAsc
    // Categories
    case mktCapChangeDesc
    case mktCapChangeAsc
    // NFT
    case floorPriceDesc
    case floorPriceAsc
    case floorPriceChangeDesc
    case floorPriceChangeAsc
    case mktCapFiatDesc
    case mktCapFiatAsc
    case volumeFiatDesc
    case volumeFiatAsc
    // Derivatives
    case openInterestDesc
    case openInterestAsc
    case priceDesc
    case priceAsc

    // MARK: - Context-specific option lists

    static var cryptoDetailOptions: [SortOption] {
        [.volumeDesc, .volumeAsc, .priceDesc, .priceAsc, .nameAsc, .nameDesc]
    }
    
    static var toplistOptions: [SortOption] {
        [.mktCapDesc, .mktCapAsc, .priceChangeDesc, .priceChangeAsc, .volumeDesc, .volumeAsc]
    }

    static var sectorOptions: [SortOption] {
        [.mktCapDesc, .mktCapAsc, .mktCapChangeDesc, .mktCapChangeAsc, .nameAsc, .nameDesc]
    }

    static var nftOptions: [SortOption] {
        [.floorPriceDesc, .floorPriceAsc, .floorPriceChangeDesc, .floorPriceChangeAsc, .mktCapFiatDesc, .mktCapFiatAsc, .volumeFiatDesc, .volumeFiatAsc]
    }
    
    static var nftDetailOptions: [SortOption] {
        [.floorPriceDesc, .floorPriceAsc, .nameDesc, .nameAsc]
    }
    
    static var exchangeDetailOptions: [SortOption] {
        [.volumeDesc, .volumeAsc, .priceDesc, .priceAsc, .nameAsc, .nameDesc]
    }

    static var exchangesOptions: [SortOption] {
        [.trustScoreDesc, .trustScoreAsc, .volumeDesc, .volumeAsc, .nameAsc, .nameDesc]
    }
    
    static var derivativesOptions: [SortOption] {
        [.openInterestDesc, .openInterestAsc, .volumeDesc, .volumeAsc, .nameAsc, .nameDesc]
    }
    
    static var derivativeDetailOptions: [SortOption] {
        [.openInterestDesc, .openInterestAsc, .priceDesc, .priceAsc]
    }

    // MARK: - API values (context-dependent)

    /// API value for toplist (coins) and exchanges endpoints
    var toplistApiValue: String {
        switch self {
        case .mktCapDesc: return "market_cap_desc"
        case .mktCapAsc: return "market_cap_asc"
        case .priceChangeDesc: return "price_change_desc"
        case .priceChangeAsc: return "price_change_asc"
        case .volumeDesc: return "volume_desc"
        case .volumeAsc: return "volume_asc"
        case .trustScoreDesc: return "trust_score_desc"
        case .trustScoreAsc: return "trust_score_asc"
        case .nameDesc: return "name_asc"
        case .nameAsc: return "name_desc"
        default: return "market_cap_desc"
        }
    }

    /// API value for categories endpoint
    var categoriesApiValue: String {
        switch self {
        case .mktCapDesc: return "market_cap_desc"
        case .mktCapAsc: return "market_cap_asc"
        case .mktCapChangeDesc: return "market_cap_change_24h_desc"
        case .mktCapChangeAsc: return "market_cap_change_24h_asc"
        default: return "market_cap_desc"
        }
    }
    
    var derivativesApiValue: String {
        switch self {
        case .openInterestDesc: return "open_interest_btc_desc"
        case .openInterestAsc: return "open_interest_btc_asc"
        case .volumeDesc: return "trade_volume_24h_btc_desc"
        case .volumeAsc: return "trade_volume_24h_btc_asc"
        case .nameAsc: return "name_asc"
        case .nameDesc: return "name_desc"
        default: return "market_cap_desc"
        }
    }

    /// API value for NFT endpoint (floor price & mkt cap share API value; client-side sort differs)
    var nftApiValue: String {
        switch self {
        case .floorPriceDesc, .floorPriceChangeDesc, .mktCapFiatDesc: return "market_cap_usd_desc"
        case .floorPriceAsc, .floorPriceChangeAsc, .mktCapFiatAsc: return "market_cap_usd_asc"
        case .volumeFiatDesc: return "h24_volume_usd_desc"
        case .volumeFiatAsc: return "h24_volume_usd_asc"
        default: return "market_cap_usd_desc"
        }
    }

    // MARK: - Toplist cache key (includes price change for price change sorts)

    func getOptionKey(priceChange: PriceChange) -> String {
        switch self {
        case .mktCapDesc, .mktCapAsc, .volumeDesc, .volumeAsc, .trustScoreDesc, .trustScoreAsc:
            toplistApiValue
        case .priceChangeDesc, .priceChangeAsc:
            "\(toplistApiValue)-\(priceChange)"
        default:
            toplistApiValue
        }
    }

    // MARK: - Display

    var title: String {
        switch self {
        case .mktCapDesc: return "Market Cap ↓"
        case .mktCapAsc: return "Market Cap ↑"
        case .priceChangeDesc: return "Price Change ↓"
        case .priceChangeAsc: return "Price Change ↑"
        case .volumeDesc: return "Volume ↓"
        case .volumeAsc: return "Volume ↑"
        case .nameAsc: return "Name (A → Z)"
        case .nameDesc: return "Name (Z → A)"
        case .mktCapChangeDesc: return "Market Cap Change ↓"
        case .mktCapChangeAsc: return "Market Cap Change ↑"
        case .floorPriceDesc: return "Floor Price ↓"
        case .floorPriceAsc: return "Floor Price ↑"
        case .floorPriceChangeDesc: return "Floor Price Change ↓"
        case .floorPriceChangeAsc: return "Floor Price Change ↑"
        case .mktCapFiatDesc: return "Market Cap ↓"
        case .mktCapFiatAsc: return "Market Cap ↑"
        case .volumeFiatDesc: return "Volume Fiat ↓"
        case .volumeFiatAsc: return "Volume Fiat ↑"
        case .trustScoreDesc: return "Trust Score ↓"
        case .trustScoreAsc: return "Trust Score ↑"
        case .openInterestDesc: return "Open Interest ↓"
        case .openInterestAsc: return "Open Interest ↑"
        case .priceDesc: return "Price ↓"
        case .priceAsc: return "Price ↑"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .mktCapDesc: return "Market Cap descending"
        case .mktCapAsc: return "Market Cap ascending"
        case .priceChangeDesc: return "Price Change descending"
        case .priceChangeAsc: return "Price Change ascending"
        case .volumeDesc: return "Volume descending"
        case .volumeAsc: return "Volume ascending"
        case .nameAsc: return "Name ascending"
        case .nameDesc: return "Name descending"
        case .mktCapChangeDesc: return "Market Cap Change descending"
        case .mktCapChangeAsc: return "Market Cap Change ascending"
        case .floorPriceDesc: return "Floor Price descending"
        case .floorPriceAsc: return "Floor Price ascending"
        case .floorPriceChangeDesc: return "Floor Price Change descending"
        case .floorPriceChangeAsc: return "Floor Price Change ascending"
        case .mktCapFiatDesc: return "Market Cap descending"
        case .mktCapFiatAsc: return "Market Cap ascending"
        case .volumeFiatDesc: return "Volume Fiat descending"
        case .volumeFiatAsc: return "Volume Fiat ascending"
        case .trustScoreDesc: return "Trust Score descending"
        case .trustScoreAsc: return "Trust Score ascending"
        case .openInterestDesc: return "Open Interest descending"
        case .openInterestAsc: return "Open Interest ascending"
        case .priceDesc: return "Price descending"
        case .priceAsc: return "Price ascending"
        }
    }

    var subtitle: String {
        switch self {
        case .mktCapDesc: return "Sort by market cap from highest to lowest"
        case .mktCapAsc: return "Sort by market cap from lowest to highest"
        case .priceChangeDesc: return "Sort by % price change from highest to lowest"
        case .priceChangeAsc: return "Sort by % price change from lowest to highest"
        case .volumeDesc: return "Sort by volume from highest to lowest"
        case .volumeAsc: return "Sort by volume from lowest to highest"
        case .nameDesc: return "Sort by name from z to a"
        case .nameAsc: return "Sort by name from a to z"
        case .mktCapChangeDesc: return "Sort by market cap change from highest to lowest"
        case .mktCapChangeAsc: return "Sort by market cap change from lowest to highest"
        case .floorPriceDesc: return "Sort by floor price from highest to lowest"
        case .floorPriceAsc: return "Sort by floor price from lowest to highest"
        case .floorPriceChangeDesc: return "Sort by floor price change from highest to lowest"
        case .floorPriceChangeAsc: return "Sort by floor price change from lowest to highest"
        case .mktCapFiatDesc: return "Sort by market cap from highest to lowest"
        case .mktCapFiatAsc: return "Sort by market cap from lowest to highest"
        case .volumeFiatDesc: return "Sort by volume fiat from highest to lowest"
        case .volumeFiatAsc: return "Sort by volume fiat from lowest to highest"
        case .trustScoreDesc: return "Sort by trust score from highest to lowest"
        case .trustScoreAsc: return "Sort by trust score from lowest to highest"
        case .openInterestDesc: return "Sort by open interest from highest to lowest"
        case .openInterestAsc: return "Sort by open interest from lowest to highest"
        case .priceDesc: return "Sort by price from highest to lowest"
        case .priceAsc: return "Sort by price from lowest to highest"
        }
    }
}
