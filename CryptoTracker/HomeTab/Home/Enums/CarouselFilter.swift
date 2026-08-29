//
//  CarouselType.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-08-01.
//

import Foundation

enum CarouselFilter: Equatable, Hashable {
    // Home
    case topCoins
    case favorites
    case trending
    case timeframeWinners
    case timeframeLosers
    case newlyListed
    
    // News
    case general
    case positive
    case neutral
    case negative
    case coins(String?)
    case exchanges(String?)
    case nfts
    case technicalAnalysis
    
    /// Returns true when this filter matches the other for selection highlighting.
    /// Filters with associated values (e.g. .coins, .exchanges) match by case, not by value.
    func matchesForSelection(_ other: CarouselFilter) -> Bool {
        switch (self, other) {
        case (.coins, .coins), (.exchanges, .exchanges):
            return true
        default:
            return self == other
        }
    }

    var rawValue: String {
        switch self {
        case .topCoins:
            "Top Coins"
        case .favorites:
            "Favorites"
        case .trending:
            "Trending"
        case .timeframeWinners:
            .preferredWinnersTimeframe
        case .timeframeLosers:
            .preferredLosersTimeframe
        case .newlyListed:
            "Newly Listed"
        case .general:
            "General"
        case .positive:
            "Positive"
        case .neutral:
            "Neutral"
        case .negative:
            "Negative"
        case .coins(let coin):
            coin ?? "Coins (Pro)"
        case .exchanges(_):
            "Exchanges (Pro)"
        case .nfts:
            "NFTs (Pro)"
        case .technicalAnalysis:
            "Technical Analysis (Pro)"
        }
    }
    
    static var homeFilters: [CarouselFilter] {
        return [.topCoins, .favorites, .trending, .timeframeWinners, .timeframeLosers, .newlyListed]
    }
    
    static var newsFilters: [CarouselFilter] {
        return [.general, .positive, .neutral, .negative, .coins(nil), .exchanges(nil), .nfts, .technicalAnalysis]
    }
    
    var shouldShowViewAll: Bool {
        switch self {
        case .topCoins, .timeframeWinners, .timeframeLosers:
            return true
        default:
            return false
        }
    }
    
    var requiresPro: Bool {
        switch self {
        case .coins, .exchanges, .nfts, .technicalAnalysis:
            return true
        default:
            return false
        }
    }
    
    var toNewsType: NewsType {
        switch self {
        case .general:
            .general
        case .positive:
            .positive
        case .neutral:
            .neutral
        case .negative:
            .negative
        case .coins(let symbol):
            .coin(symbol: symbol ?? "")
        case .exchanges(let id):
            .exchange(id: id ?? "")
        case .nfts:
            .nft
        case .technicalAnalysis:
            .technicalAnalysis
        default:
            .general
        }
    }
}
