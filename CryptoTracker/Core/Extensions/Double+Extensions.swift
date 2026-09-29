//
//  Double+Extensions.swift
//  CryptoCurrently
//
//  Created by Oscar Berggren on 2020-11-01.
//

import Foundation
import SwiftUI

func +? (lhs: Double?, rhs: Double?) -> Double? {
    guard let lhs = lhs, let rhs = rhs else { return nil }
    return lhs + rhs
}

extension Decimal {
    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }
}

extension Double {
    fileprivate static func localizedCountdown(_ key: String) -> String {
        #if IS_APP
        Localization.string(key)
        #else
        key
        #endif
    }

    fileprivate static func localizedCountdownCount(_ key: String, _ count: Int) -> String {
        #if IS_APP
        Localization.format(key, count)
        #else
        String(format: key, count)
        #endif
    }

    /// Returns a human-readable string for time until this Unix timestamp (e.g. "5 hours", "3 days", "2 months").
    /// Returns "Expired" if the date is in the past.
    var timeUntilExpired: String {
        let expirationDate = Date(timeIntervalSince1970: self)
        let now = Date()
        guard expirationDate > now else { return Self.localizedCountdown("Expired") }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day, .month], from: now, to: expirationDate)
        
        if let months = components.month, months > 0 {
            return months == 1 ? Self.localizedCountdown("1 month") : Self.localizedCountdownCount("%d months", months)
        } else if let days = components.day, days > 0 {
            return days == 1 ? Self.localizedCountdown("1 day") : Self.localizedCountdownCount("%d days", days)
        } else if let hours = components.hour, hours >= 0 {
            return hours <= 1 ? Self.localizedCountdown("1 hour") : Self.localizedCountdownCount("%d hours", hours)
        } else if let minutes = components.minute, minutes >= 0 {
            return minutes <= 1 ? Self.localizedCountdown("1 minute") : Self.localizedCountdownCount("%d minutes", minutes)
        }
        return Self.localizedCountdown("Less than 1 minute")
    }

    var roundToHundreds: Int {
        let rounded = (self / 100.0).rounded()
        return 100 * Int(rounded)
    }

    var safeValue: Double {
        return self.isNaN ? 1 : self
    }
    
#if IS_APP || IS_WATCH
    var changeColor: Color {
        if self > 0 {
            return Color.trendUp
        } else if self < 0 {
            return Color.trendDown
        } else {
            return Color.onSurfaceDim
        }
    }
#elseif IS_WIDGET
    func changeColor(for scheme: ColorScheme) -> Color {
        if self > 0 {
            return .trendUp(for: scheme)
        } else if self < 0 {
            return .trendDown(for: scheme)
        } else {
            return .onSurfaceDim(for: scheme)
        }
    }
#endif
    
    var changeImage: Image? {
        if self > 0 {
            return .trendUp
        } else if self < 0 {
            return .trendDown
        } else {
            return .trendStill
        }
    }
    
    var directionShape: UIBezierPath {
        if self > 0 {
            return .priceUpTriangle
        } else if self < 0 {
            return .priceDownTriangle
        } else {
            return .priceStillTriangle
        }
    }
    
    var changePercentDecimalPoints: Int {
        if abs(self) >= 1000 {
            return 2
        } else if abs(self) >= 100 {
            return 1
        } else {
            return 2
        }
    }
    
    func formattedChangePercent(includePercentSign: Bool = true) -> String {
        let absValue = abs(self)
        let threshold = FormattingThreshold.allCases.first(where: { absValue >= $0.rawValue }) ?? .none
        let formattedValue: String
        
        if threshold == .none {
            let decimals = changePercentDecimalPoints
            let rounded = absValue.roundTo(places: decimals)
            formattedValue = rounded.formatted(.number.precision(.fractionLength(decimals)))
        } else {
            let shortened = (absValue / threshold.rawValue).roundTo(places: 2)
            formattedValue = "\(shortened.formatted(.number.precision(.fractionLength(2))))\(threshold.symbol)"
        }
        
        return includePercentSign ? "\(formattedValue)%" : formattedValue
    }
    
    var changePercentAccessible: String {
        let absValue = abs(self)
        let threshold = FormattingThreshold.allCases.first(where: { absValue >= $0.rawValue }) ?? .none
        
        if threshold == .none {
            return absValue.numberAccessible(maxPlaces: changePercentDecimalPoints)
        }
        
        let shortened = (absValue / threshold.rawValue).roundTo(places: 2)
        return "\(shortened.numberAccessible(maxPlaces: 2)) \(threshold.symbol.spellOutSuffix.lowercased())"
    }
    
    var changeValueDecimalPoints: Int {
        return abs(self) < 1 ? 4 : 2
    }
    
    var directionSymbol: String {
        return self >= 0 ? "+" : ""
    }
    
    var directionAccessible: String {
        return self >= 0 ? "Up" : "Down"
    }

    
    static func getDifferenceInPercent(between a: Double?, and b: Double?) -> Double? {
        guard let a, let b else {
            return nil
        }
        
        let delta = a - b
        let difference = (100 * (delta / (b)))
        
        return difference.isNaN ? 0 : difference
    }
    
    static func getDifferenceInDecimal(between a: Double, and b: Double) -> Double? {
        let delta = a - b
        let difference = 1 + (delta / b)
        
        return difference.isNaN || difference.isInfinite ? nil : difference
    }
    
    func roundTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    func getChangeInValue(currentValue: Double) -> Double {
        let factor = (self / 100) + 1
        // -100% means the value went to zero; previous can't be recovered from current alone.
        guard factor != 0 else { return -currentValue }

        let previousValue = currentValue / factor
        return currentValue - previousValue
    }
    
    func formatCurrency(
        threshold: FormattingThreshold? = nil,
        currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel(),
        minDecimals: Int? = nil,
        maxDecimals: Int? = nil,
        accessible: Bool = false
    ) -> String {
        if let threshold, threshold == FormattingThreshold.none || abs(self) < threshold.rawValue {
            return formattedString(
                amount: self,
                threshold: FormattingThreshold.none,
                currency: currency,
                minDecimals: minDecimals,
                maxDecimals: maxDecimals,
                accessible: accessible
            )
            .replacingOccurrences(of: "  ", with: " ")
        }
        return formattedString(
            amount: self,
            threshold: FormattingThreshold.allCases.first(where: { abs(self) >= $0.rawValue }) ?? .none,
            currency: currency,
            minDecimals: minDecimals,
            maxDecimals: maxDecimals,
            accessible: accessible
        )
        .replacingOccurrences(of: "  ", with: " ")
    }
    
    func formatAccessibleCurrency(
        compactFrom threshold: FormattingThreshold = .million,
        currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    ) -> String {
        guard abs(self) >= threshold.rawValue else {
            let amountText = numberAccessible(maxPlaces: accessibleDecimalPlacesForVoiceOver())
            let currencyName = currency.voiceOverCurrencyName
            guard !currencyName.isEmpty else { return amountText }
            return "\(amountText) \(currencyName)"
        }
        
        return formatCurrency(threshold: .thousand, currency: currency, accessible: true)
    }
    
    private func accessibleDecimalPlacesForVoiceOver() -> Int {
        if abs(self) < 1 { return 7 }
        if abs(self) < 100 { return 4 }
        if abs(self) < 10_000 { return 2 }
        return 0
    }
    
    private func formattedString(
        amount: Double,
        threshold: FormattingThreshold,
        currency: CurrencyModel,
        minDecimals: Int? = nil,
        maxDecimals: Int? = nil,
        accessible: Bool
    ) -> String {
        let symbolPrefix = currency.suffix ? "" : currency.symbol
        let symbolSuffix = currency.suffix ? " \(threshold.symbol.isEmpty ? "" : " ")\(currency.symbol)" : ""
        let formattedValue = amount / threshold.rawValue
        let maxDecimals = maxDecimals ?? (abs(amount) < 1 ? 7 : 2)
        let roundedFormattedValue = formattedValue.roundTo(places: maxDecimals)
        let numberFormatter = NumberFormatter()
        
        numberFormatter.currencySymbol = accessible ? "" : symbolPrefix
        numberFormatter.locale = Locale.withLatinNumerals(identifier: currency.locale)
        numberFormatter.numberStyle = accessible ? .spellOut : .currency
        numberFormatter.minimumFractionDigits = accessible ? 0 : minDecimals ?? 2
        numberFormatter.maximumFractionDigits = maxDecimals
        
        let formattedAmount = numberFormatter.string(from: NSNumber(value: accessible ? roundedFormattedValue : formattedValue))?.trimmingCharacters(in: .whitespaces) ?? ""
        
        if accessible {
            let currencyName = currency.voiceOverCurrencyName
            if threshold == .none {
                return "\(formattedAmount) \(currencyName)"
            }
            return "\(formattedAmount) \(threshold.symbol.spellOutSuffix.lowercased()) \(currencyName)"
        } else {
            return "\(formattedAmount)\(threshold.symbol)\(symbolSuffix)"
        }
    }

    
    func getPriceDirectionShape(currentPrice: Double?, forceShowPercent: Bool = false) -> UIBezierPath {
        let roundedDouble = !getShowChangesInPercent() && !forceShowPercent ? self : self.roundTo(places: 2)
        
        if !getShowChangesInPercent() {
            let previousValue = (currentPrice ?? 0) / ((self / 100) + 1)
            let change = (currentPrice ?? 0) - previousValue
            
            if abs(change) < 0.0000001 {
                return UIBezierPath.priceStillTriangle
            }
        }
        
        if roundedDouble > 0 {
            return UIBezierPath.priceUpTriangle
        } else if roundedDouble < 0 {
            return UIBezierPath.priceDownTriangle
        } else {
            return UIBezierPath.priceStillTriangle
        }
    }
    
    func getPriceDirectionShapePortfolio(currentPrice: Double?, forceShowPercent: Bool = false) -> UIBezierPath {
        let roundedDouble = !forceShowPercent ? self : self.roundTo(places: 2)
        
        if !forceShowPercent {
            if abs(self) < 0.0000001 {
                return UIBezierPath.priceStillTriangle
            }
        }
        
        if roundedDouble > 0 {
            return UIBezierPath.priceUpTriangle
        } else if roundedDouble < 0 {
            return UIBezierPath.priceDownTriangle
        } else {
            return UIBezierPath.priceStillTriangle
        }
    }
    
    func getPriceWithSymbol(currentPrice: Double? = nil, fixedCurrency: CurrencyModel? = nil, showSign: Bool = false, fromPriceChange: Bool = true, forceShowPercent: Bool = false) -> String {
        
        var value = self.roundTo(places: 2)
        
        if getShowChangesInPercent() || forceShowPercent {
            
            if self > 9999 {
                return ">9999"
            } else if self < -9999 {
                return "<9999"
            }
            
            if value == -0.0 {
                value = 0.0
            }
            
            if value >= 0 {
                return "\(showSign ? "+" : "")\(String(format: "%.2f", value))"
            } else {
                var value = "\(String(format: "%.2f", value))"
                
                if !showSign {
                    value = value.replacingOccurrences(of: "-", with: "")
                }
                
                return value
            }
            
        } else {
            
            let previousValue = (currentPrice ?? 0) / ((self / 100) + 1)
            let change = (currentPrice ?? 0) - previousValue
            let currency = fixedCurrency ?? SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
            let changeStyle = CurrencyFormatStyle.compact(from: .thousand, currency: currency, isPriceChange: fromPriceChange)
            var changeText = change.formatted(style: changeStyle)
            
            if !showSign {
                return abs(change).formatted(style: changeStyle).replacingOccurrences(of: "+", with: "")
                
            } else {
                changeText = (change >= 0 ? "+" : "-") + changeText
            }
            
            return changeText
            
        }
    }
    
    func getShowChangesInPercent() -> Bool {
        return SettingsManager.shared.get(key: GlobalSettingKey.changesInPercent) ?? true
    }
    
    func currencyAccessible(currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel(), maxDecimals: Int? = nil) -> String {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = false
        currencyFormatter.numberStyle = .spellOut
        currencyFormatter.locale = Locale(identifier: Locale.current.identifier)
        currencyFormatter.currencySymbol = currency.symbol
        
        let value = abs(self.roundTo(places: maxDecimals ?? (abs(self) < 1 ? 4 : 2)))
        
        return "\(currencyFormatter.string(from: value as NSNumber) ?? "") \(currency.voiceOverCurrencyName)"
    }
    
    func numberAccessible(maxPlaces: Int = 7) -> String {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = false
        currencyFormatter.numberStyle = .spellOut
        currencyFormatter.locale = Locale(identifier: Locale.current.identifier)
        
        let places = abs(self) < 1 ? maxPlaces : 2

        return currencyFormatter.string(from: abs(self.roundTo(places: places)) as NSNumber) ?? ""
    }
    
    func removeZerosFromEnd(maximumDigits: Int = 2, force: Bool = false) -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 2
        formatter.decimalSeparator = "."
        formatter.maximumFractionDigits = abs(self) < 1 && !force ? 7 : maximumDigits
        return String(formatter.string(from: number) ?? "")
    }
    
    /// Formats the number with locale-appropriate decimal separator, removing trailing zeros.
    func formattedRemovingTrailingZeros(locale: Locale = .current, maximumDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = abs(self) < 1 ? 7 : maximumDigits
        return formatter.string(from: NSNumber(value: self)) ?? "0"
    }
    
    func formatAsCurrency(currencyModel: CurrencyModel?, maxFractions: Int = 7, minimumDigits: Int = 2) -> String? {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ""
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = min(minimumDigits, maxFractions)
        formatter.maximumFractionDigits = abs(self) < 1 ? maxFractions : maxFractions < minimumDigits ? maxFractions : 2
        formatter.currencySymbol = currencyModel?.suffix ?? true ? "" : currencyModel?.symbol ?? "$"
        formatter.locale = Locale.withLatinNumerals(identifier: currencyModel?.locale ?? "en_US")
        return formatter.string(from: NSNumber(value: self))?.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: "+", with: "")
    }
    
}
