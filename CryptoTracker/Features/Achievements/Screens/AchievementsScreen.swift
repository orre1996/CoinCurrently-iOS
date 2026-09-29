//
//  AchievementsScreen.swift
//  CoinCurrently
//

import SwiftUI

struct AchievementsScreen: View {
    @State private var viewModel = AchievementsViewModel()

    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    summarySection

                    ForEach(AchievementCategory.allCases) { category in
                        let items = viewModel.progress(for: category)
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                SettingsSectionHeader(title: category.rawValue)

                                VStack(spacing: 16) {
                                    ForEach(items) { item in
                                        AchievementRowView(progress: item)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationBarTitle(Localization.string("Achievements"), displayMode: .inline)
        .task {
            await viewModel.loadAchievements()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.backFromBackground)) { _ in
            Task {
                await viewModel.loadAchievements()
            }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.string("Your progress"))
                .font(.satoshiBold(22))
                .foregroundStyle(Color.onSurface)

            HStack(spacing: 16) {
                summaryStat(
                    title: Localization.string("Levels"),
                    value: "\(viewModel.summary.unlockedLevels)/\(viewModel.summary.totalLevels)"
                )

                summaryStat(
                    title: Localization.string("Current streak"),
                    value: Localization.format("%d days", viewModel.summary.currentStreak)
                )

                summaryStat(
                    title: Localization.string("Best streak"),
                    value: Localization.format("%d days", viewModel.summary.longestStreak)
                )
            }
        }
        .padding(16)
        .cardBackground(hasPadding: false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Localization.format(
                "Your progress. %d of %d levels unlocked. Current streak %d days. Best streak %d days.",
                viewModel.summary.unlockedLevels,
                viewModel.summary.totalLevels,
                viewModel.summary.currentStreak,
                viewModel.summary.longestStreak
            )
        )
    }

    private func summaryStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.satoshiMedium(12))
                .foregroundStyle(Color.onSurfaceDim)

            Text(value)
                .font(.satoshiBold(16))
                .foregroundStyle(Color.onSurface)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
