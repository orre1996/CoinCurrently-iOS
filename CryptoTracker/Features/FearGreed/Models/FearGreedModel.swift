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
}
