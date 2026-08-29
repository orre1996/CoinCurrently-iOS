//
//  AchievementStreakTracker.swift
//  CoinCurrently
//

import Foundation

enum AchievementStreakTracker {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func recordAppOpen() {
        let today = dateFormatter.string(from: Date())
        let settings = SettingsManager.shared

        let lastOpenDate: String? = settings.get(key: AppSettingKey.achievementLastOpenDate)
        var currentStreak: Int = settings.get(key: AppSettingKey.achievementCurrentStreak) ?? 0
        var longestStreak: Int = settings.get(key: AppSettingKey.achievementLongestStreak) ?? 0

        if lastOpenDate == today {
            return
        }

        let previousStreak = Double(currentStreak)

        if let lastOpenDate,
           let lastDate = dateFormatter.date(from: lastOpenDate),
           let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           dateFormatter.string(from: yesterday) == dateFormatter.string(from: lastDate) {
            currentStreak += 1
        } else if lastOpenDate == nil {
            currentStreak = 1
        } else {
            currentStreak = 1
        }

        longestStreak = max(longestStreak, currentStreak)

        settings.set(data: today, key: AppSettingKey.achievementLastOpenDate)
        settings.set(data: currentStreak, key: AppSettingKey.achievementCurrentStreak)
        settings.set(data: longestStreak, key: AppSettingKey.achievementLongestStreak)

        let newStreak = Double(currentStreak)
        Task { @MainActor in
            await AchievementManager.shared.checkMetricUnlock(
                for: .dailyStreak,
                previousValue: previousStreak,
                newValue: newStreak
            )
        }
    }

    static var currentStreak: Int {
        SettingsManager.shared.get(key: AppSettingKey.achievementCurrentStreak) ?? 0
    }

    static var longestStreak: Int {
        SettingsManager.shared.get(key: AppSettingKey.achievementLongestStreak) ?? 0
    }
}
