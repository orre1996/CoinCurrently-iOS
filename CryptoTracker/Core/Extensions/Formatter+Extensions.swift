//
//  Formatter+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-01-15.
//

import Foundation

extension Locale {
    /// Preserves regional formatting (separators, etc.) but always uses Western digits (0–9).
    static func withLatinNumerals(identifier: String) -> Locale {
        Locale(identifier: "\(identifier)@numbers=latn")
    }
}

extension Formatter {
    static let withSeparatorPortfolioAmount: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ","
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 7
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
}
