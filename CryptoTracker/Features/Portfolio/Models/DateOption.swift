//
//  DateOption.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/13/26.
//

import SwiftUI

extension DateOption {
    var startDate: Date? {
        switch self {
        case .custom(let start, _):
            return start
        default:
            return nil
        }
    }
    
    var endDate: Date? {
        switch self {
        case .custom(_, let end):
            return end
        default:
            return nil
        }
    }
    
    var type: Self {
        switch self {
        case .custom:
            return .custom(startDate: .distantPast, endDate: .distantFuture)
        default:
            return self
        }
    }
}

enum DateOption: CaseIterable, Hashable, Equatable {
    case all
    case lastWeek
    case lastMonth
    case lastThreeMonths
    case lastSixMonths
    case lastYear
    case yearToDate
    case custom(startDate: Date?, endDate: Date?)

    static var allCases: [DateOption] {
        [
            .all,
            .lastWeek,
            .lastMonth,
            .lastThreeMonths,
            .lastSixMonths,
            .lastYear,
            .yearToDate,
            .custom(startDate: .now, endDate: .now)
        ]
    }

    var title: String {
        switch self {
        case .all:
            "All"
        case .lastWeek:
            "Last week"
        case .lastMonth:
            "Last month"
        case .lastThreeMonths:
            "Last 3 months"
        case .lastSixMonths:
            "Last 6 months"
        case .lastYear:
            "Last year"
        case .yearToDate:
            "Year to date"
        case .custom(_, _):
            "Custom"
        }
    }
    
    var rangeTitle: String {
        switch self {
        case .all:
            return "Date"
        case .custom(let startDate, let endDate):
            let startDateFormatted = startDate?.formatted(date: .abbreviated, time: .omitted) ?? ""
            let endDateFormatted = endDate?.formatted(date: .abbreviated, time: .omitted) ?? ""
            return "\(startDateFormatted) - \(endDateFormatted)"
        default:
            return title
        }
    }
}
