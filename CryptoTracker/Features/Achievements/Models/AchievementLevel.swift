//
//  AchievementLevel.swift
//  CoinCurrently
//

import Foundation

struct AchievementLevel: Identifiable, Equatable {
    let id: String
    let name: String
    let threshold: Double
    let description: String

    init(name: String, threshold: Double, description: String) {
        self.id = "\(name)-\(threshold)"
        self.name = name
        self.threshold = threshold
        self.description = description
    }
}

enum AchievementLevelTier {
    static let bronze = "Bronze"
    static let silver = "Silver"
    static let gold = "Gold"
    static let platinum = "Platinum"
    static let diamond = "Diamond"
    static let master = "Master"
}
