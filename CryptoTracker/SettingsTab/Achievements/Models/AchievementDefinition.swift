//
//  AchievementDefinition.swift
//  CoinCurrently
//

import Foundation

struct AchievementDefinition: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let category: AchievementCategory
    let icon: String
    let metric: AchievementMetric
    let levels: [AchievementLevel]
    let valueFormat: AchievementValueFormat

    enum AchievementValueFormat: Equatable {
        case integer
        case percent
        case boolean
    }
}
