//
//  AchievementMetric.swift
//  CoinCurrently
//

import Foundation

enum AchievementMetric: String, CaseIterable, Codable {
    case dailyStreak
    case favoritesCount
    case portfolioTransactions
    case portfolioExports
    case maxPortfolioGainPercent
    case priceAlertsCount
    case widgetCoinsCount
    case uniqueSearches
    case cryptoDetailsViewed
    case compareSessions
    case newsArticlesOpened
    case nftDetailsViewed
    case exchangeDetailsViewed
    case sectorDetailsViewed
    case fearGreedVisits
    case gasFeesVisits
    case treasuryVisits
    case candleChartToggles
    case converterUses
    case authenticationEnabled
    case referralsCompleted
    case selfRedeems
}

enum AchievementCounterKey: String, CaseIterable, Codable {
    case cryptoDetailsViewed
    case compareSessions
    case converterUses
    case newsArticlesOpened
    case nftDetailsViewed
    case exchangeDetailsViewed
    case sectorDetailsViewed
    case fearGreedVisits
    case gasFeesVisits
    case treasuryVisits
    case candleChartToggles
    case referralsCompleted
    case selfRedeems
    case portfolioExports

    var metric: AchievementMetric {
        AchievementMetric(rawValue: rawValue)!
    }
}
