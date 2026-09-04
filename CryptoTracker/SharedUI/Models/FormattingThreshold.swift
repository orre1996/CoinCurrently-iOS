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
    /// Compact-from only. Declared after `thousand` so `allCases.first` still abbreviates with K.
    case hundredThousand = 100_000
    case tenThousand = 10_000
    case none = 1

    var symbol: String {
        switch self {
        case .trillion:
            return "T"
        case .billion:
            return "B"
        case .million:
            return "M"
        case .thousand, .hundredThousand, .tenThousand:
            return "K"
        case .none:
            return ""
        }
    }
}

enum NumberFormatContext: Sendable, Equatable {
    case currency
    case portfolioAmount
}

struct CurrencyFormatStyle: Sendable, Equatable {
    var threshold: FormattingThreshold
    var currency: CurrencyModel?
    var compact: Bool
    var context: NumberFormatContext
    var isPriceChange: Bool
    var roundsToNiceNumber: Bool
    var maxFractionDigits: Int?

    static func exact(
        currency: CurrencyModel?,
        roundsToNiceNumber: Bool = false,
        maxFractionDigits: Int? = nil
    ) -> CurrencyFormatStyle {
        CurrencyFormatStyle(
            threshold: .none,
            currency: currency,
            compact: false,
            context: .currency,
            isPriceChange: false,
            roundsToNiceNumber: roundsToNiceNumber,
            maxFractionDigits: maxFractionDigits
        )
    }

    static func compact(
        from threshold: FormattingThreshold,
        currency: CurrencyModel? = nil,
        isPriceChange: Bool = false,
        roundsToNiceNumber: Bool = false,
        maxFractionDigits: Int? = nil
    ) -> CurrencyFormatStyle {
        CurrencyFormatStyle(
            threshold: threshold,
            currency: currency,
            compact: true,
            context: .currency,
            isPriceChange: isPriceChange,
            roundsToNiceNumber: roundsToNiceNumber,
            maxFractionDigits: maxFractionDigits
        )
    }

    static func portfolioAmount(
        from threshold: FormattingThreshold = .thousand
    ) -> CurrencyFormatStyle {
        CurrencyFormatStyle(
            threshold: threshold,
            currency: nil,
            compact: threshold != .none,
            context: .portfolioAmount,
            isPriceChange: false,
            roundsToNiceNumber: false,
            maxFractionDigits: nil
        )
    }
}

enum CurrencyFormatter {
    static func string(from value: Double, style: CurrencyFormatStyle) -> String {
        switch style.context {
        case .portfolioAmount:
            return portfolioAmount(value, compactFrom: style.compact ? style.threshold.rawValue : .infinity)
        case .currency:
            return currency(value, style: style)
        }
    }

    private static func currency(_ value: Double, style: CurrencyFormatStyle) -> String {
        guard !value.isInfinite else {
            return "Overloaded"
        }

        let selectedCurrency = style.currency
        let suffix = selectedCurrency?.suffix ?? true ? " \(selectedCurrency?.symbol ?? "")" : ""
        var price = value
        var minimumDigits = 2

        if style.roundsToNiceNumber {
            if price > 10_000_000_000 {
                price = roundUp(price, 1_000_000_000)
            } else if price > 1_000_000_000 {
                price = roundUp(price, 100_000_000)
            } else if price > 1_000_000 {
                price = roundUp(price, 1_000_000)
            } else if price > 100_000 {
                price = roundUp(price, 10_000)
            } else if price > 10_000 {
                price = roundUp(price, 100)
            } else if price > 1_000 {
                price = roundUp(price, 10)
            } else if price > 50 {
                price = roundUp(price, 1.0)
            } else if price > 10 {
                price = (price * 5).rounded() / 5.0
            } else if price > 6 {
                price = (price * 10).rounded() / 10.0
            } else if price > 1.1 {
                price = (price * 50).rounded() / 50.0
            } else if price > 0.1 {
                minimumDigits = 3
                price = ((price * 100) / 100.0).roundTo(places: 3)
            } else if price > 0.01 {
                minimumDigits = 3
                price = ((price * 1_000) / 1_000.0).roundTo(places: 3)
            } else {
                minimumDigits = 7
                price = ((price * 100_000) / 100_000.0).roundTo(places: 7)
            }
        }

        var maxDigits = style.maxFractionDigits ?? 7

        if style.isPriceChange {
            if abs(value) < 1 {
                maxDigits = 4
            }

            if abs(value) < 0.0000001 {
                return (0.formatAsCurrency(currencyModel: selectedCurrency, maxFractions: 2) ?? "0.00")
                    .trimmingCharacters(in: .whitespacesAndNewlines) + suffix
            } else if abs(value) < 0.0001 {
                return ((value * 1000).formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00")
                    .trimmingCharacters(in: .whitespacesAndNewlines) + "m" + suffix
            }
        }

        let compactFrom = style.compact ? style.threshold.rawValue : Double.infinity

        if compactFrom.isInfinite {
            return (price.formatAsCurrency(
                currencyModel: selectedCurrency,
                maxFractions: maxDigits,
                minimumDigits: minimumDigits
            ) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + suffix
        }

        if let unit = compactUnit(for: abs(value), compactFrom: compactFrom) {
            return ((value / unit.divisor).formatAsCurrency(
                currencyModel: selectedCurrency,
                maxFractions: maxDigits
            ) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + unit.suffix + suffix
        }

        return (value.formatAsCurrency(
            currencyModel: selectedCurrency,
            maxFractions: maxDigits
        ) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + suffix
    }

    private static func portfolioAmount(_ value: Double, compactFrom: Double) -> String {
        guard !value.isInfinite else {
            return "Overloaded"
        }

        if let unit = compactUnit(for: abs(value), compactFrom: compactFrom, includeQuadrillion: false) {
            return (value / unit.divisor).formattedWithPortfolioAmount + unit.suffix
        }

        return value.formattedWithPortfolioAmount
    }

    private static func compactUnit(
        for absValue: Double,
        compactFrom: Double,
        includeQuadrillion: Bool = true
    ) -> (divisor: Double, suffix: String)? {
        guard absValue >= compactFrom else {
            return nil
        }

        if includeQuadrillion, absValue >= 1_000_000_000_000_000 {
            return (1_000_000_000_000_000, "Q")
        }
        if absValue >= 1_000_000_000_000 {
            return (1_000_000_000_000, "T")
        }
        if absValue >= 1_000_000_000 {
            return (1_000_000_000, "B")
        }
        if absValue >= 1_000_000 {
            return (1_000_000, "M")
        }
        if absValue >= 1_000 {
            return (1_000, "K")
        }
        return nil
    }

    private static func roundUp(_ number: Double, _ near: Double) -> Double {
        if number.truncatingRemainder(dividingBy: near) == 0.0 {
            return number
        }

        return Double(Int((number / near).rounded()) * Int(near))
    }
}

extension Double {
    func formatted(style: CurrencyFormatStyle) -> String {
        CurrencyFormatter.string(from: self, style: style)
    }
}
