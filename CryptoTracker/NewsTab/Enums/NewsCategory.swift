//
//  NewsCategory.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-10.
//

import Foundation

enum NewsCategory: String, Codable {
    case General = "General"
    case Technical_Analysis = "Technical Analysis"
    case Positive = "Positive"
    case Neutral = "Neutral"
    case Negative = "Negative"
    case Coin = "Coin"
    case Exchanges = "Exchanges"
    case NFT = "NFT"
}
