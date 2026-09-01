//
//  PriceChange.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/24/26.
//

enum PriceChange: String, CaseIterable, Codable {
    case oneHour = "1h"
    case oneDay = "24h"
    case sevenDays = "7d"
    case oneMonth = "30d"
    
    var subtitle: String {
        switch self {
        case .oneHour:
            "Price change in the last hour"
        case .oneDay:
            "Price change in the last 24 hours"
        case .sevenDays:
            "Price change in the last 7 days"
        case .oneMonth:
            "Price change in the last 14 days"
        }
    }
    
    var accessibilityTimeframe: String {
        switch self {
        case .oneHour:
            return "1 hour"
        case .oneDay:
            return "24 hour"
        case .sevenDays:
            return "7 days"
        case .oneMonth:
            return "30 days"
        }
    }
}
