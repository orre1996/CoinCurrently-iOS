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
    var selfRedeems: Int = 0
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
        case .selfRedeems:
            selfRedeems += 1
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
        case .selfRedeems:
            selfRedeems
        case .portfolioExports:
            portfolioExports
        }
    }
}

extension AchievementCounters {
    enum CodingKeys: String, CodingKey {
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
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cryptoDetailsViewed = try container.decodeIfPresent(Int.self, forKey: .cryptoDetailsViewed) ?? 0
        compareSessions = try container.decodeIfPresent(Int.self, forKey: .compareSessions) ?? 0
        converterUses = try container.decodeIfPresent(Int.self, forKey: .converterUses) ?? 0
        newsArticlesOpened = try container.decodeIfPresent(Int.self, forKey: .newsArticlesOpened) ?? 0
        nftDetailsViewed = try container.decodeIfPresent(Int.self, forKey: .nftDetailsViewed) ?? 0
        exchangeDetailsViewed = try container.decodeIfPresent(Int.self, forKey: .exchangeDetailsViewed) ?? 0
        sectorDetailsViewed = try container.decodeIfPresent(Int.self, forKey: .sectorDetailsViewed) ?? 0
        fearGreedVisits = try container.decodeIfPresent(Int.self, forKey: .fearGreedVisits) ?? 0
        gasFeesVisits = try container.decodeIfPresent(Int.self, forKey: .gasFeesVisits) ?? 0
        treasuryVisits = try container.decodeIfPresent(Int.self, forKey: .treasuryVisits) ?? 0
        candleChartToggles = try container.decodeIfPresent(Int.self, forKey: .candleChartToggles) ?? 0
        referralsCompleted = try container.decodeIfPresent(Int.self, forKey: .referralsCompleted) ?? 0
        selfRedeems = try container.decodeIfPresent(Int.self, forKey: .selfRedeems) ?? 0
        portfolioExports = try container.decodeIfPresent(Int.self, forKey: .portfolioExports) ?? 0
    }
}
