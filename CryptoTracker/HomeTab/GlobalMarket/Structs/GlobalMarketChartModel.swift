//
//  GlobalMarketChartModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-07-20.
//

import Foundation

struct GlobalMarketChartModel: Codable, Equatable {
    let market_cap_chart: GlobalMarketChartData?
}

struct GlobalMarketChartData: Codable, Equatable {
    let market_cap: [[Double?]]?
    let volume: [[Double?]]?
}
