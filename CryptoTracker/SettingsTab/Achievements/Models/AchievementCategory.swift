//
//  AchievementCategory.swift
//  CoinCurrently
//

import Foundation

enum AchievementCategory: String, CaseIterable, Identifiable {
    case streaks = "Streaks"
    case portfolio = "Portfolio"
    case favorites = "Favorites"
    case tools = "Tools"
    case explorer = "Explorer"
    case security = "Security"

    var id: String { rawValue }
}
