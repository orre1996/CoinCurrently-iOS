//
//  CandleStickChartModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-07-12.
//

import Foundation
import SwiftUI

struct CandleStickChartModel: Codable {
    var candle: [Candle]? = []
}

struct Candle: Codable {
    var timestamp: Double?
    var open: Double?
    var high: Double?
    var low: Double?
    var close: Double?

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        timestamp = try container.decode(Double.self)
        open = try container.decode(Double.self)
        high = try container.decode(Double.self)
        low = try container.decode(Double.self)
        close = try container.decode(Double.self)
    }
}
