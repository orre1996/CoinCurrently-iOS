//
//  AchievementCounters.swift
//  CoinCurrently
//

import Foundation

struct AchievementCounters: Codable, Equatable {
    var cryptoDetailsViewed: Int = 0
    var compareSessions: Int = 0
    var converterUses: Int = 0
    var newsArticlesOpened: Int = 0
    var nftDetailsViewed: Int = 0
    var exchangeDetailsViewed: Int = 0
    var sectorDetailsViewed: Int = 0
    var fearGreedVisits: Int = 0
    var gasFeesVisits: Int = 0
    var treasuryVisits: Int = 0
    var candleChartToggles: Int = 0
    var referralsCompleted: Int = 0
    var portfolioExports: Int = 0

    mutating func increment(_ key: AchievementCounterKey) {
        switch key {
        case .cryptoDetailsViewed:
            cryptoDetailsViewed += 1
        case .compareSessions:
            compareSessions += 1
        case .converterUses:
            converterUses += 1
        case .newsArticlesOpened:
            newsArticlesOpened += 1
        case .nftDetailsViewed:
            nftDetailsViewed += 1
        case .exchangeDetailsViewed:
            exchangeDetailsViewed += 1
        case .sectorDetailsViewed:
            sectorDetailsViewed += 1
        case .fearGreedVisits:
            fearGreedVisits += 1
        case .gasFeesVisits:
            gasFeesVisits += 1
        case .treasuryVisits:
            treasuryVisits += 1
        case .candleChartToggles:
            candleChartToggles += 1
        case .referralsCompleted:
            referralsCompleted += 1
        case .portfolioExports:
            portfolioExports += 1
        }
    }

    func value(for key: AchievementCounterKey) -> Int {
        switch key {
        case .cryptoDetailsViewed:
            cryptoDetailsViewed
        case .compareSessions:
            compareSessions
        case .converterUses:
            converterUses
        case .newsArticlesOpened:
            newsArticlesOpened
        case .nftDetailsViewed:
            nftDetailsViewed
        case .exchangeDetailsViewed:
            exchangeDetailsViewed
        case .sectorDetailsViewed:
            sectorDetailsViewed
        case .fearGreedVisits:
            fearGreedVisits
        case .gasFeesVisits:
            gasFeesVisits
        case .treasuryVisits:
            treasuryVisits
        case .candleChartToggles:
            candleChartToggles
        case .referralsCompleted:
            referralsCompleted
        case .portfolioExports:
            portfolioExports
        }
    }
}
