//
//  PortfolioPieSlice.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-07-28.
//

import Foundation

struct PortfolioPieSlice: Identifiable, Hashable {
    let id: String
    let symbol: String
    let name: String
    let percentage: Double
    let color: String?
    let outerStartAngle: Double
    let outerEndAngle: Double
    let innerStartAngle: Double
    let innerEndAngle: Double
}
