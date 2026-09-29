//
//  AchievementLevelCardView.swift
//  CoinCurrently
//

import SwiftUI

struct AchievementLevelCardView: View {
    let level: AchievementLevel
    let levelIndex: Int
    let progress: AchievementProgress
    let valueFormat: AchievementDefinition.AchievementValueFormat

    private var state: AchievementLevelState {
        progress.levelState(at: levelIndex)
    }

    private var progressFraction: Double {
        progress.progressFraction(for: level, at: levelIndex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Localization.string(level.name))
                    .font(.satoshiBold(14))
                    .foregroundStyle(state == .locked ? Color.onSurfaceDimmer : Color.onSurface)

                Spacer(minLength: 0)

                if state == .unlocked {
                    Image.checkmark
                        .foregroundStyle(Color.primary)
                        .accessibilityHidden(true)
                } else if state == .locked {
                    Image.lock
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .accessibilityHidden(true)
                }
            }

            Text(Localization.string(level.description))
                .font(.satoshiMedium(12))
                .foregroundStyle(Color.onSurfaceDim)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if state == .inProgress {
                CustomProgressBarView(
                    progress: progressFraction,
                    foregroundColor: .primary,
                    backgroundColor: .surfaceContainerHigh,
                    height: 6
                )

                Text(progressLabel)
                    .font(.satoshiMedium(12))
                    .foregroundStyle(Color.onSurfaceDim)
            } else if state == .unlocked {
                Text(Localization.string("Unlocked"))
                    .font(.satoshiMedium(12))
                    .foregroundStyle(Color.primary)
            } else {
                Text(Localization.string("Locked"))
                    .font(.satoshiMedium(12))
                    .foregroundStyle(Color.onSurfaceDimmer)
            }
        }
        .padding(12)
        .frame(width: 128, alignment: .leading)
        .cardBackground(
            hasPadding: false,
            backgroundColor: cardBackgroundColor,
            cornerRadius: 12,
            outlineColor: cardOutlineColor
        )
        .opacity(state == .locked ? 0.65 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var cardBackgroundColor: Color {
        switch state {
        case .unlocked:
            return .secondary15
        case .inProgress:
            return .surfaceContainer
        case .locked:
            return .surfaceContainerLow
        }
    }

    private var cardOutlineColor: Color {
        state == .unlocked ? .primary : .outlineVariant
    }

    private var progressLabel: String {
        let current = formattedValue(progress.currentValue)
        let target = formattedValue(level.threshold)
        return "\(current)/\(target)"
    }

    private func formattedValue(_ value: Double) -> String {
        switch valueFormat {
        case .integer, .boolean:
            return Int(value).formatted()
        case .percent:
            return "\(Int(value))%"
        }
    }

    private var accessibilityLabel: String {
        let status: String
        switch state {
        case .unlocked:
            status = Localization.string("unlocked")
        case .inProgress:
            status = Localization.format("in progress, %@", progressLabel)
        case .locked:
            status = Localization.string("locked")
        }
        return Localization.format(
            "%@ level, %@, %@",
            Localization.string(level.name),
            Localization.string(level.description),
            status
        )
    }
}
