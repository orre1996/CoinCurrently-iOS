//
//  ChartButton.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-02-05.
//

import Foundation

struct ChartButton: Hashable {
    let time: String
    let days: String
    let timeChart: TimeCharts
    let accessibilityText: String
    
    static func getButtons(from: TimeCharts, to: TimeCharts) -> [ChartButton] {
        return (from.rawValue...to.rawValue).map({
            guard let timeChart = TimeCharts(rawValue: $0) else { return nil }

            return ChartButton(time: timeChart.timeframe,
                               days: timeChart.days,
                               timeChart: timeChart,
                               accessibilityText: timeChart.accessibilityText)
        }).compactMap({ $0 })
    }

    static let treasuryTimeCharts: [TimeCharts] = [
        .aWeek, .aMonth, .threeMonths, .sixMonths, .aYear, .twoYears
    ]

    static func treasuryDetailButtons() -> [ChartButton] {
        treasuryTimeCharts.map {
            ChartButton(
                time: $0.timeframe,
                days: $0.days,
                timeChart: $0,
                accessibilityText: $0.accessibilityText
            )
        }
    }

    static func getTreasuryStartTimeFrame() -> TimeCharts {
        let current: TimeCharts = SettingsManager.shared.get(key: AppSettingKey.timeframe) ?? .aWeek

        if treasuryTimeCharts.contains(current) {
            return current
        }

        switch current {
        case .anHour, .aDay:
            return .aWeek
        case .max:
            return .twoYears
        default:
            return .aWeek
        }
    }
}
