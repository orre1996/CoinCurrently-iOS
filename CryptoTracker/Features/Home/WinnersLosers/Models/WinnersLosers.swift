//
//  WinnersLosers.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-12-26.
//

import Foundation

struct WinnersLosers: Codable {
    let top_gainers: [WinnerLoser]
    let top_losers: [WinnerLoser]
}

struct WinnerLoser: Codable {
    let id: String
}
