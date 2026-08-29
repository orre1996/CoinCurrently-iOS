//
//  TreasuryHoldingChartModel.swift
//  CoinCurrently
//

import Foundation

struct TreasuryHoldingChartModel: Codable, Equatable {
    var holdings: [[Double?]]?
    var holding_value_in_usd: [[Double?]]?
    var prices: [[Double?]]?
    var market_caps: [[Double?]]?
    var total_volumes: [[Double?]]?
}
