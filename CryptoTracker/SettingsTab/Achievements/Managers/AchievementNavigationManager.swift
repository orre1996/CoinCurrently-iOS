//
//  AchievementNavigationManager.swift
//  CoinCurrently
//

import Foundation

#if IS_APP
@MainActor
enum AchievementNavigationManager {
    private static weak var navigationViewModel: NavigationViewModel?
    private static var pendingUnlocks: [AchievementUnlockEvent] = []

    static func register(_ viewModel: NavigationViewModel) {
        navigationViewModel = viewModel

        guard !pendingUnlocks.isEmpty else { return }

        let unlocks = pendingUnlocks
        pendingUnlocks.removeAll()

        for unlock in unlocks {
            present(unlock, on: viewModel)
        }
    }

    static func showUnlock(_ unlock: AchievementUnlockEvent) {
        guard let viewModel = navigationViewModel else {
            pendingUnlocks.append(unlock)
            return
        }

        present(unlock, on: viewModel)
    }

    private static func present(_ unlock: AchievementUnlockEvent, on viewModel: NavigationViewModel) {
        viewModel.showAchievementSnackbar(
            achievementTitle: unlock.achievementTitle,
            levelName: unlock.levelName
        )
    }
}
#endif
