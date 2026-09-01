//
//  ChangeDirection.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 6/28/25.
//

import SwiftUI

enum ChangeDirection: String, CaseIterable {
    case up = "up"
    case down = "down"
    
    var symbol: String {
        switch self {
        case .up:
            return "+%"
        case .down:
            return "-%"
        }
    }
    
    var color: Color {
        switch self {
        case .up:
            return .trendUp
        case .down:
            return .trendDown
        }
    }
    
    func operation() -> (Double, Double) -> Double {
        return self == .up ? (+) : (-)
    }
}
