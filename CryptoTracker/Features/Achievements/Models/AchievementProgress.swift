//
//  AchievementProgress.swift
//  CoinCurrently
//

import Foundation

struct AchievementProgress: Identifiable, Equatable {
    let definition: AchievementDefinition
    let currentValue: Double
    let unlockedLevelIndex: Int

    var id: String { definition.id }

    var isFullyUnlocked: Bool {
        unlockedLevelIndex >= definition.levels.count - 1
    }

    var nextLevelIndex: Int? {
        guard !isFullyUnlocked else { return nil }
        return unlockedLevelIndex + 1
    }

    var nextThreshold: Double? {
        guard let index = nextLevelIndex else { return nil }
        return definition.levels[index].threshold
    }

    func levelState(at index: Int) -> AchievementLevelState {
        if index <= unlockedLevelIndex {
            return .unlocked
        }
        if index == unlockedLevelIndex + 1 {
            return .inProgress
        }
        return .locked
    }

    func progressFraction(for level: AchievementLevel, at index: Int) -> Double {
        guard index == unlockedLevelIndex + 1 || (unlockedLevelIndex == -1 && index == 0) else {
            return index <= unlockedLevelIndex ? 1 : 0
        }

        let previousThreshold = index > 0 ? definition.levels[index - 1].threshold : 0
        let range = level.threshold - previousThreshold
        guard range > 0 else { return currentValue >= level.threshold ? 1 : 0 }
        let progressInRange = currentValue - previousThreshold
        return min(max(progressInRange / range, 0), 1)
    }
}

enum AchievementLevelState: Equatable {
    case unlocked
    case inProgress
    case locked
}

struct AchievementsSummary: Equatable {
    let unlockedLevels: Int
    let totalLevels: Int
    let currentStreak: Int
    let longestStreak: Int
}
