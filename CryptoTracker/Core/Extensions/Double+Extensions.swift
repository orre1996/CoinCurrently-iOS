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
    /// Returns a human-readable string for time until this Unix timestamp (e.g. "5 hours", "3 days", "2 months").
    /// Returns "Expired" if the date is in the past.
    var timeUntilExpired: String {
        let expirationDate = Date(timeIntervalSince1970: self)
        let now = Date()
        guard expirationDate > now else { return "Expired" }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .day, .month], from: now, to: expirationDate)
        
        if let months = components.month, months > 0 {
            return months == 1 ? "1 month" : "\(months) months"
        } else if let days = components.day, days > 0 {
            return days == 1 ? "1 day" : "\(days) days"
        } else if let hours = components.hour, hours >= 0 {
            return hours <= 1 ? "1 hour" : "\(hours) hours"
        } else if let minutes = components.minute, minutes >= 0 {
            return minutes <= 1 ? "1 minute" : "\(minutes) minutes"
        }
        return "Less than 1 minute"
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
            var changeText = change.getFormattedString(fromThousand: true, selectedCurrency: fixedCurrency ?? SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel(), fromPriceChange: fromPriceChange)
            
            if !showSign {
                
                return abs(change).getFormattedString(fromThousand: true, selectedCurrency: fixedCurrency ?? SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel(), fromPriceChange: fromPriceChange).replacingOccurrences(of: "+", with: "")
                
            } else {
                changeText = (change >= 0 ? "+" : "-") + changeText
            }
            
            return changeText
            
        }
    }
    
    func getShowChangesInPercent() -> Bool {
        return SettingsManager.shared.get(key: GlobalSettingKey.changesInPercent) ?? true
    }
    
    func roundUp(_ number: Double, _ near: Double) -> Double {
        if number.truncatingRemainder(dividingBy: near) == 0.0 {
            return number
        }
        
        return Double(Int((number / near).rounded()) * Int(near))
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
    
    func getFormattedString(fromTenK: Bool = false, fromThousand: Bool = false, fromHundredK: Bool = false, fromMillion: Bool = false, fromTrillion: Bool = false, dontShort: Bool = false, selectedCurrency: CurrencyModel? = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel(), fromPortfolioView: Bool = false, fromPriceChange: Bool = false, roundToClosest: Bool = false, forceMaxDigits: Int? = nil) -> String {
        guard !self.isInfinite else {
            return "Overloaded"
        }
        
        let suffix = selectedCurrency?.suffix ?? true ? " \(selectedCurrency?.symbol ?? "")" : ""
        
        var price = self

        var minimumDigits = 2

         // Värden över 2.147 miljarder blir fucked om de är double, därav toBigDecimal
         if roundToClosest {
             if (price > 10_000_000_000) {
                 price = roundUp(price,  1_000_000_000)
             } else if (price > 1_000_000_000) {
                 price = roundUp(price, 100_000_000)
             } else if (price > 1_000_000) {
                 price = roundUp(price, 1_000_000)
             } else if (price > 100_000) {
                 price =  roundUp(price, 10_000)
             } else if (price > 10_000) {
                 price =  roundUp(price, 100)
             } else if (price > 1_000) {
                 price = roundUp(price, 10)
             } else if (price > 50) {
                 price = roundUp(price, 1.0)
             } else if (price > 10) {
                 price = (price * 5).rounded() / 5.0
             } else if (price > 6) {
                 price = (price * 10).rounded() / 10.0
             } else if (price > 1.1) {
                 price = (price * 50).rounded() / 50.0
             } else if (price > 0.1) {
                 minimumDigits = 3
                 price = ((price * 100) / 100.0).roundTo(places: 3)
             } else if (price > 0.01) {
                 minimumDigits = 3
                 price = ((price * 1_000) / 1_000.0).roundTo(places: 3)
             } else {
                 minimumDigits = 7
                 price = ((price * 100_000) / 100_000.0).roundTo(places: 7)
             }
         }
        
        var maxDigits = forceMaxDigits ?? 7
        
        if fromPriceChange {
            
            let prefix = fromPortfolioView && self > 0 ? "+" : ""
            
            if abs(self) < 1 {
                maxDigits = 4
            }
            
            if abs(self) < 0.0000001 {
                return prefix + (0.formatAsCurrency(currencyModel: selectedCurrency, maxFractions: 2) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + suffix
            } else if abs(self) < 0.0001 {
                return prefix + ((self * 1000).formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + "m" + suffix
            }
            
        }
        
        if dontShort {
            let prefix = fromPortfolioView && price > 0 ? "+" : ""
            return prefix + (price.formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits, minimumDigits: minimumDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + suffix
        }
        
        if abs(self) >= 1000000000000000 {
            let prefix = fromPortfolioView && self > 0 ? "+" : ""
            return prefix + ((self/1000000000000000).formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + "Q" + suffix
        }
        
        if fromTrillion {
            let prefix = fromPortfolioView && self > 0 ? "+" : ""
            if abs(self) >= 1000000000000 {
                return prefix + ((self/1000000000000).formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + "T" + suffix
            } else {
                return prefix + (self.formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + suffix
            }
        }
        
        if abs(self) >= 1000000000000 {
            let prefix = fromPortfolioView && self > 0 ? "+" : ""
            return prefix + ((self/1000000000000).formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.0").trimmingCharacters(in: .whitespacesAndNewlines) + "T" + suffix
        }
        else if abs(self) >= 1000000000 {
            let prefix = fromPortfolioView && self > 0 ? "+" : ""
            return prefix + ((self/1000000000).formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + "B" + suffix
        }
        else if abs(self) >= 1000000 {
            let prefix = fromPortfolioView && self > 0 ? "+" : ""
            return prefix + ((self/1000000).formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + "M" + suffix
        }
        else if abs(self) >= 1000 {
            
            if fromMillion {
                let prefix = fromPortfolioView && self > 0 ? "+" : ""
                if abs(self) >= 1000000 {
                    return prefix + ((self/1000000).formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + "M" + suffix
                } else {
                    return prefix + (self.formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + suffix
                }
            }
            
            else if fromHundredK {
                let prefix = fromPortfolioView && self > 0 ? "+" : ""
                if abs(self) >= 100000 {
                    return prefix + ((self/1000).formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + "K" + suffix
                } else {
                    return prefix + (self.formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + suffix
                }
            }
            
            else if fromTenK {
                let prefix = fromPortfolioView && self > 0 ? "+" : ""
                if abs(self) >= 10000 {
                    return prefix + ((self/1000).formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + "K" + suffix
                } else {
                    return prefix + (self.formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + suffix
                }
                
            } else if fromTenK {
                let prefix = fromPortfolioView && self > 0 ? "+" : ""
                if abs(self) >= 1000 {
                    return prefix + ((self/1000).formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + "K" + suffix
                } else {
                    return prefix + (self.formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + suffix
                }
                
            } else {
                let prefix = fromPortfolioView && self > 0 ? "+" : ""
                return prefix + ((self/1000).formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + "K" + suffix
            }
        } else {
            let prefix = fromPortfolioView && self > 0 ? "+" : ""
            return prefix + (self.formatAsCurrency(currencyModel: selectedCurrency, maxFractions: maxDigits) ?? "0.00").trimmingCharacters(in: .whitespacesAndNewlines) + suffix
        }
    }
    
    func getFormattedStringNoCurrency(fromTenK: Bool = false, fromHundredK: Bool = false, fromTrillion: Bool = false, dontShort: Bool = false) -> String {
        guard !self.isInfinite else {
            return "Overloaded"
        }
        
        if dontShort {
            return self.formattedWithSeparatorNoCurrency
        }
        
        if fromTrillion {
            if abs(self) >= 1000000000000 {
                return (self/1000000000000).formattedWithSeparatorNoCurrency + "T"
            } else {
                return self.formattedWithSeparatorNoCurrency
            }
        }
        
        if abs(self) >= 1000000000000 {
            return (self/1000000000000).formattedWithSeparatorNoCurrency + "T"
        }
        else if abs(self) >= 1000000000 {
            return (self/1000000000).formattedWithSeparatorNoCurrency + "B"
        }
        else if abs(self) >= 1000000 {
            return (self/1000000).formattedWithSeparatorNoCurrency + "M"
        }
        else if abs(self) >= 1000 {
            
            if fromHundredK {
                if abs(self) >= 100000 {
                    return (self/1000).formattedWithSeparatorNoCurrency + "K"
                } else {
                    return self.formattedWithSeparatorNoCurrency
                }
            }
            
            else if fromTenK {
                if abs(self) >= 10000 {
                    return (self/1000).formattedWithSeparatorNoCurrency + "K"
                } else {
                    return self.formattedWithSeparatorNoCurrency
                }
                
            } else {
                return (self/1000).formattedWithSeparatorNoCurrency + "K"
            }
        } else {
            return self.formattedWithSeparatorNoCurrency
        }
    }
    
    func getFormattedStringNoCurrencyPortfolioAmount(fromTenK: Bool = false, fromHundredK: Bool = false, fromTrillion: Bool = false, dontShort: Bool = false) -> String {
        guard !self.isInfinite else {
            return "Overloaded"
        }
        
        if dontShort {
            return self.formattedWithPortfolioAmount
        }
        
        if fromTrillion {
            if abs(self) >= 1000000000000 {
                return (self/1000000000000).formattedWithPortfolioAmount + "T"
            } else {
                return self.formattedWithPortfolioAmount
            }
        }
        
        if abs(self) >= 1000000000000 {
            return (self/1000000000000).formattedWithPortfolioAmount + "T"
        }
        else if abs(self) >= 1000000000 {
            return (self/1000000000).formattedWithPortfolioAmount + "B"
        }
        else if abs(self) >= 1000000 {
            return (self/1000000).formattedWithPortfolioAmount + "M"
        }
        else if abs(self) >= 1000 {
            
            if fromHundredK {
                if abs(self) >= 100000 {
                    return (self/1000).formattedWithPortfolioAmount + "K"
                } else {
                    return self.formattedWithPortfolioAmount
                }
            }
            
            else if fromTenK {
                if abs(self) >= 10000 {
                    return (self/1000).formattedWithPortfolioAmount + "K"
                } else {
                    return self.formattedWithPortfolioAmount
                }
                
            } else {
                return (self/1000).formattedWithPortfolioAmount + "K"
            }
        } else {
            return self.formattedWithPortfolioAmount
        }
    }
    
    func getFormattedStringNoCurrencyWidget(fromThousand: Bool = false, fromTenK: Bool = false, fromHundredK: Bool = false, fromTrillion: Bool = false) -> String {
        guard !self.isInfinite else {
            return "Overloaded"
        }
        
        if fromTrillion {
            if abs(self) >= 1000000000000 {
                return (self/1000000000000).formattedWithSeparatorNoCurrencyWidget + "T"
            } else {
                return self.formattedWithSeparatorNoCurrencyWidget
            }
        }
        
        if abs(self) >= 1000000000000 {
            return (self/1000000000000).formattedWithSeparatorNoCurrencyWidget + "T"
        }
        else if abs(self) >= 1000000000 {
            return (self/1000000000).formattedWithSeparatorNoCurrencyWidget + "B"
        }
        else if abs(self) >= 1000000 {
            return (self/1000000).formattedWithSeparatorNoCurrencyWidget + "M"
        }
        else if abs(self) >= 1000 {
            
            if fromHundredK {
                if abs(self) >= 100000 {
                    return (self/1000).formattedWithSeparatorNoCurrencyWidget + "K"
                } else {
                    return self.formattedWithSeparatorNoCurrencyWidget
                }
            }
            
            else if fromTenK {
                if abs(self) >= 10000 {
                    return (self/1000).formattedWithSeparatorNoCurrencyWidget + "K"
                } else {
                    return self.formattedWithSeparatorNoCurrencyWidget
                }
                
            } else if fromThousand {
                if abs(self) >= 1000 {
                    return (self/1000).formattedWithSeparatorNoCurrencyWidget + "K"
                } else {
                    return self.formattedWithSeparatorNoCurrencyWidget
                }
                
            }  else {
                return (self/1000).formattedWithSeparatorNoCurrencyWidget + "K"
            }
        } else {
            return self.formattedWithSeparatorNoCurrencyWidget
        }
    }
    
    func getFormattedStringCalcuator(selectedCurrency: CurrencyModel?) -> String {
        guard !self.isInfinite else {
            return "Overloaded"
        }
        
        let suffix = selectedCurrency?.suffix ?? true ? " \(selectedCurrency?.symbol ?? "")" : ""
        
        if abs(self) >= 1000000000000000 {
            return ((self/1000000000000000).removeZerosFromEndFormattedCalculator(currencyModel: selectedCurrency)).trimmingCharacters(in: .whitespacesAndNewlines) + "Q" + suffix
        }
        
        if abs(self) >= 1000000000000 {
            return ((self/1000000000000).removeZerosFromEndFormattedCalculator(currencyModel: selectedCurrency)).trimmingCharacters(in: .whitespacesAndNewlines) + "T" + suffix
        }
        
        return (self.removeZerosFromEndFormattedCalculator(currencyModel: selectedCurrency)).trimmingCharacters(in: .whitespacesAndNewlines) + suffix
        
    }

    func getLength() -> String? {
        var shortened = 0.0
        if abs(self) >= 1000000000000 {
            shortened = self/1000000000000
        }
        else if abs(self) >= 1000000000 {
            shortened = self/1000000000
        }
        else if abs(self) >= 1000000 {
            shortened = self/1000000
        }
        else if abs(self) >= 1000 {
            shortened = self/1000
        }
        else {
            shortened = self
        }
        let count = Int(shortened)
        
        return "\(4 - String(count).count)"
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
    
    func removeZerosFromEndFormatted(currencyModel: CurrencyModel?) -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.groupingSeparator = ""
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = abs(self) < 1 ? 4 : 2
        formatter.locale = Locale.withLatinNumerals(identifier: currencyModel?.locale ?? "en_US")
        formatter.currencySymbol = currencyModel?.suffix ?? true ? "" : currencyModel?.symbol ?? "$"
        return String(formatter.string(from: number) ?? "")
    }
    
    func removeZerosFromEndFormattedCalculator(currencyModel: CurrencyModel?) -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.groupingSeparator = ""
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = abs(self) < 0.1 ? 7 : 4
        formatter.locale = Locale.withLatinNumerals(identifier: currencyModel?.locale ?? "en_US")
        formatter.currencySymbol = currencyModel?.suffix ?? true ? "" : currencyModel?.symbol ?? "$"
        return String(formatter.string(from: number) ?? "")
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
