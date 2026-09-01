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
        .navigationBarTitle("Achievements", displayMode: .inline)
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
            Text("Your progress")
                .font(.satoshiBold(22))
                .foregroundStyle(Color.onSurface)

            HStack(spacing: 16) {
                summaryStat(
                    title: "Levels",
                    value: "\(viewModel.summary.unlockedLevels)/\(viewModel.summary.totalLevels)"
                )

                summaryStat(
                    title: "Current streak",
                    value: "\(viewModel.summary.currentStreak) days"
                )

                summaryStat(
                    title: "Best streak",
                    value: "\(viewModel.summary.longestStreak) days"
                )
            }
        }
        .padding(16)
        .cardBackground(hasPadding: false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Your progress. \(viewModel.summary.unlockedLevels) of \(viewModel.summary.totalLevels) levels unlocked. Current streak \(viewModel.summary.currentStreak) days. Best streak \(viewModel.summary.longestStreak) days."
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
