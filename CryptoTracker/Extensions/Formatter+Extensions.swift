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
    static let withSeparator: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = " "
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    static let withSeparatorNoCurrency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ","
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    static let withSeparatorPortfolioAmount: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ","
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 7
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    static let withSeparatorNoCurrencyWidget: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ","
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    static let withSeparatorNoCurrencyWithSpaces: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = " "
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 7
        return formatter
    }()
}
