//
//  AchievementRowView.swift
//  CoinCurrently
//

import SwiftUI

struct AchievementRowView: View {
    let progress: AchievementProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: progress.definition.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(Color.primary)
                    .frame(width: 32, height: 32)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(Localization.string(progress.definition.title))
                        .font(.satoshiBold(16))
                        .foregroundStyle(Color.onSurface)

                    Text(Localization.string(progress.definition.description))
                        .font(.satoshiMedium(14))
                        .foregroundStyle(Color.onSurfaceDim)

                    Text(subtitleText)
                        .font(.satoshiMedium(12))
                        .foregroundStyle(Color.onSurfaceDimmer)
                }
            }
            .padding(.horizontal, 16)

            ScrollViewReader { scrollReader in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(progress.definition.levels.enumerated()), id: \.element.id) { index, level in
                            AchievementLevelCardView(
                                level: level,
                                levelIndex: index,
                                progress: progress,
                                valueFormat: progress.definition.valueFormat
                            )
                            .id(level.id)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .onAppear {
                    scrollToActiveLevel(using: scrollReader)
                }
                .onChange(of: progress.unlockedLevelIndex) { _, _ in
                    scrollToActiveLevel(using: scrollReader)
                }
            }
        }
        .padding(.vertical, 16)
        .cardBackground(hasPadding: false)
    }

    private var subtitleText: String {
        let unlockedCount = max(0, progress.unlockedLevelIndex + 1)
        let totalCount = progress.definition.levels.count
        return Localization.format("%d/%d levels unlocked", unlockedCount, totalCount)
    }

    private func scrollToActiveLevel(using scrollReader: ScrollViewProxy) {
        let targetIndex: Int
        if progress.isFullyUnlocked {
            targetIndex = progress.definition.levels.count - 1
        } else {
            targetIndex = max(0, progress.unlockedLevelIndex + 1)
        }
        guard targetIndex < progress.definition.levels.count else { return }
        let targetLevel = progress.definition.levels[targetIndex]
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                scrollReader.scrollTo(targetLevel.id, anchor: .center)
            }
        }
    }
}
