//
//  TimeCharts.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-09.
//

import Foundation

enum TimeCharts: Int, Comparable, Codable {
    static func < (lhs: TimeCharts, rhs: TimeCharts) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    case anHour = 0
    case aDay = 1
    case aWeek = 2
    case aMonth = 3
    case threeMonths = 4
    case aYear = 5
    case max = 6
    case sixMonths = 7
    case twoYears = 8
    
    var timeframe: String {
        switch self {
        case .anHour:
            return "1H"
            
        case .aDay:
            return "1D"
            
        case .aWeek:
            return "7D"
            
        case .aMonth:
            return "1M"
            
        case .threeMonths:
            return "3M"
            
        case .aYear:
            return "1Y"
            
        case .max:
            return "ALL"

        case .sixMonths:
            return "6M"

        case .twoYears:
            return "2Y"
        }
    }
    
    var timeframeFormatted: String {
        switch self {
        case .anHour:
            return "1h:"
            
        case .aDay:
            return "1d:"
            
        case .aWeek:
            return "7d:"
            
        case .aMonth:
            return "1m:"
            
        case .threeMonths:
            return "3m:"
            
        case .aYear:
            return "1y:"
            
        case .max:
            return "All:"

        case .sixMonths:
            return "6m:"

        case .twoYears:
            return "2y:"
        }
    }
    
    var days: String {
        switch self {
        case .anHour, .aDay:
            return "1"
            
        case .aWeek:
            return "7"
            
        case .aMonth:
            return "30"
            
        case .threeMonths:
            return "90"
            
        case .aYear:
            return "365"
            
        case .max:
            return "max"

        case .sixMonths:
            return "180"

        case .twoYears:
            return "730"
        }
    }
    
    var interval: String? {
        switch self {
        case .anHour, .aDay, .aWeek:
            return nil
        default:
            return "daily"
        }
    }
    
    var accessibilityText: String {
        switch self {
        case .anHour:
            return "1 hour"
            
        case .aDay:
            return "24 hour"
            
        case .aWeek:
            return "7 days"
            
        case .aMonth:
            return "1 month"
            
        case .threeMonths:
            return "3 months"
            
        case .aYear:
            return "1 year"
            
        case .max:
            return "max"

        case .sixMonths:
            return "6 months"

        case .twoYears:
            return "2 years"
        }
    }
    
    var accessibilityTimeframe: String {
        switch self {
        case .anHour:
            return "1 hour"
        case .aDay:
            return "24 hour"
        case .aWeek:
            return "7 days"
        case .aMonth:
            return "30 days"
        case .threeMonths:
            return "3 months"
        case .aYear:
            return "1 year"
        case .max:
            return "all time"
        case .sixMonths:
            return "180 days"
        case .twoYears:
            return "2 years"
        }
    }
    
    var timeAgoText: String {
        switch self {
        case .anHour:
            return "This Hour"
            
        case .aDay:
            return "Today"
            
        case .aWeek:
            return "Past Week"
            
        case .aMonth:
            return "Past Month"
            
        case .threeMonths:
            return "Past 3 Months"
            
        case .aYear:
            return "Past Year"
            
        case .max:
            return "All Time"

        case .sixMonths:
            return "Past 6 Months"

        case .twoYears:
            return "Past 2 Years"
        }
    }
    
    var dateFormat: String {
        switch self {
        case .anHour, .aDay:
            return Date.uses24HourClock ? "HH:mm" : "hh:mm a"
            
        case .aWeek, .aMonth, .threeMonths, .sixMonths:
            return "MMM dd"
            
        case .aYear, .twoYears:
            return "MMM"
            
        case .max:
            return "YYYY"
        }
    }
    
    static func getStartTimeFrame(between a: TimeCharts, and b: TimeCharts) -> TimeCharts {
        let currentTimeframe: TimeCharts = SettingsManager.shared.get(key: AppSettingKey.timeframe) ?? .aWeek
        
        if currentTimeframe < a {
            return a
        } else if currentTimeframe > b {
            return b
        } else {
            return currentTimeframe
        }
    }
    
    var rangeTitle: String {
        switch self {
        case .anHour:
            "1 Hour Range"
        case .aDay:
            "24 Hour Range"
        case .aWeek:
            "1 Week Range"
        case .aMonth:
            "1 Month Range"
        case .threeMonths:
            "3 Month Range"
        case .aYear:
            "1 Year Range"
        case .max:
            "Full Range"
        case .sixMonths:
            "6 Month Range"
        case .twoYears:
            "2 Year Range"
        }
    }
}
