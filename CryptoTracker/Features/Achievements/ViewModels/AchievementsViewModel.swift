//
//  AchievementsViewModel.swift
//  CoinCurrently
//

import Foundation

@MainActor
@Observable
final class AchievementsViewModel {
    private let achievementManager: AchievementManager

    var progressItems: [AchievementProgress] = []
    var summary = AchievementsSummary(unlockedLevels: 0, totalLevels: 0, currentStreak: 0, longestStreak: 0)
    var isLoading = false

    init(achievementManager: AchievementManager = .shared) {
        self.achievementManager = achievementManager
        progressItems = achievementManager.cachedProgress
        summary = achievementManager.cachedSummary
    }

    func loadAchievements() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let progress = await achievementManager.computeAllProgress()
        progressItems = progress
        summary = achievementManager.computeSummary(from: progress)
    }

    func progress(for category: AchievementCategory) -> [AchievementProgress] {
        progressItems.filter { $0.definition.category == category }
    }
}
