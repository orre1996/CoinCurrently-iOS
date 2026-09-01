//
//  AlertCoin.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-09-29.
//

import Foundation

enum AlertDirection: String, Codable {
    case above = "above"
    case below = "below"
}

struct AlertCoin: Codable, Hashable {
    enum CodingKeys: String, CodingKey {
        case id = "alertId"
        case targetPrice = "price"
        case coinId,
             resetThreshold,
             direction,
             preferredCurrency,
             createdDate
    }
    
    let id: String
    let resetThreshold: Double?
    let direction: AlertDirection
    let coinId: String
    let targetPrice: Double
    let preferredCurrency: String
    let createdDate: String
    
    var isRecurringAlert: Bool {
        return resetThreshold != nil
    }
}

struct PostAlertCoin: Codable {
    let coinId: String
    let targetPrice: Double
    let direction: AlertDirection
    let resetThreshold: Double?
    let preferredCurrency: String
}

enum AddPriceAlertResult: Equatable {
    case success
    case failure
    case fcmTokenUnavailable
}
