//
//  TimeCharts+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-08.
//

import Foundation

extension TimeCharts {
    static func getPreferredTimeframeFearGreedChart() -> TimeCharts {
        switch SettingsManager.shared.get(key: GlobalSettingKey.selectedTimeframe) ?? PreferredTimeframe.weekly {
            case .daily, .weekly:
                return .aWeek

            case .monthly:
                return .aMonth
        }
    }
}
