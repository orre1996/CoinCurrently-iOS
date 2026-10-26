//
//  CarouselType.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-08-01.
//

import Foundation

enum CarouselFilter: Equatable, Hashable {
    case topCoins
    case favorites
    case trending
    case timeframeWinners
    case timeframeLosers
    case newlyListed

    func matchesForSelection(_ other: CarouselFilter) -> Bool {
        self == other
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
        }
    }
    
    static var homeFilters: [CarouselFilter] {
        return [.topCoins, .favorites, .trending, .timeframeWinners, .timeframeLosers, .newlyListed]
    }

    /// Home opens on Favorites when the user already has a list; otherwise Top Coins.
    static func defaultHomeFilter(hasFavorites: Bool) -> CarouselFilter {
        hasFavorites ? .favorites : .topCoins
    }
    
    var shouldShowViewAll: Bool {
        switch self {
        case .topCoins, .timeframeWinners, .timeframeLosers:
            return true
        default:
            return false
        }
    }
}
