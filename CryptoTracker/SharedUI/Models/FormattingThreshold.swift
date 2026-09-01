//
//  FormattingThreshold.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 3/31/25.
//

import Foundation

enum FormattingThreshold: Double, CaseIterable {
    case trillion = 1_000_000_000_000
    case billion = 1_000_000_000
    case million = 1_000_000
    case thousand = 1_000
    case none = 1
    
    var symbol: String {
        switch self {
        case .trillion:
            return "T"
        case .billion:
            return "B"
        case .million:
            return "M"
        case .thousand:
            return "K"
        case .none:
            return ""
        }
    }
}
