//
//  FearGreedModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-12-21.
//

import Foundation

struct FearGreed: Codable, Equatable {
    var name: String? = nil
    var data: [FearGreedItem]? = nil
}

struct FearGreedItem: Codable, Equatable {
    let value: String?
    let value_classification: String?
    let timestamp: String?
    let time_until_update: String?
    
    func getUpdateInText() -> String {
        let temp = (Int(time_until_update ?? "0") ?? 0) / 60
        let hours = (Int(time_until_update ?? "0") ?? 0) / 60 / 60
        let minutes = temp % 60
        return (hours > 0 ? ("\(hours)" + "h ") : "") + "\(minutes)m"
    }
    
    func getLastUpdatedText() -> String {
        let temp = (Int(time_until_update ?? "0") ?? 0) / 60
        let dayInMilliseconds = (86400000 / 1000 / 60) - temp
        let hours = dayInMilliseconds / 60
        let minutes = dayInMilliseconds % 60
        return (hours > 0 ? ("\(hours)" + "h ") : "") + "\(minutes)m ago"
    }
}
