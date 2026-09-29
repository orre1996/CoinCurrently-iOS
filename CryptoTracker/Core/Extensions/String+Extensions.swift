//
//  String+Extensions.swift
//  CryptoCurrently
//
//  Created by Oscar Berggren on 2020-11-01.
//

import Foundation
import SwiftUI
import UIKit

enum DateFormat: String {
    case MMMddyyyy = "MMM dd, yyyy"
    case yyyyMMdd = "yyyy-MM-dd"
    case EdMMMyyyyHHmmssZ = "E, d MMM yyyy HH:mm:ss Z"
    case yyyyMMddTHHmmssSSSZ = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
}


enum AppCopy {
    static func string(_ key: String) -> String {
        #if IS_APP
        Localization.string(key)
        #else
        key
        #endif
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        #if IS_APP
        String(format: Localization.string(key), locale: Localization.locale, arguments: arguments)
        #else
        String(format: key, arguments: arguments)
        #endif
    }
}

extension StringProtocol  {
    var digits: [Int] { compactMap(\.wholeNumberValue) }
}

extension String: @retroactive Identifiable {
    public var id: String { return self }
    
    static let stars = "∗∗∗∗∗∗"
    
    static var platformSource: String {
#if IS_APP
        return "iOS-App-"
#elseif IS_WIDGET
        return "iOS-Widget-"
#elseif IS_WATCH
        return "iOS-Watch-"
#endif
    }
    
    static let appName = "CoinCurrently"
    static let groupIdentifier = "group.com.Cryptium.CoinCurrently"
    static let trialReminder = "reminder"
    static let trialReminderId = "reminderNotification"
    static let usd = "usd"

    static let tabIndex = "tabIndex"
    
    static let homeTab = "home"
    static let homeTabFilled = "home_filled"
    static let portfolioTab = "portfolio"
    static let portfolioTabFilled = "portfolio_filled"
    static let marketTab = "market"
    static let marketTabFilled = "market_filled"
    static let newsTab = "news"
    static let newsTabFilled = "news_filled"
    static let settingsTab = "settings"
    static let settingsTabFilled = "settings_filled"
    
    var spellOutSuffix: String {
        switch self {
        case "T":
            return self.replacingOccurrences(of: "T", with: "Trillion")
        case "B":
            return self.replacingOccurrences(of: "B", with: "Billion")
        case "M":
            return self.replacingOccurrences(of: "M", with: "Million")
        case "K":
            return self.replacingOccurrences(of: "K", with: "Thousand")
        default:
            return ""
        }
    }
    
    static var timeframeAccessible: String {
        switch SettingsManager.shared.get(key: GlobalSettingKey.selectedTimeframe) ?? PreferredTimeframe.weekly {
        case .daily:
            return "24 hours"
        case .weekly:
            return "7 days"
        case .monthly:
            return "30 days"
        }
    }

    static var preferredTimeFrameText: String {
        switch SettingsManager.shared.get(key: GlobalSettingKey.selectedTimeframe) ?? PreferredTimeframe.weekly {
            case .daily:
                return "24H:"
            
            case .weekly:
                return "7D:"
            
            case .monthly:
                return "30D:"
        }
    }
    

    static var preferredTimeFrameTextChange: String {
        return preferredTimeFrameText.replacingOccurrences(of: ":", with: "")
    }
    
    static var preferredTimeFrameRaw: String {
        switch SettingsManager.shared.get(key: GlobalSettingKey.selectedTimeframe) ?? PreferredTimeframe.weekly {
            case .daily:
                return "1"
            
            case .weekly:
                return "7"
            
            case .monthly:
                return "30"
        }
    }
    
    static var getPreferredTimeFrameRaw: String {
        switch SettingsManager.shared.get(key: GlobalSettingKey.selectedTimeframe) ?? PreferredTimeframe.weekly {
            case .daily:
                return "1"
            
            case .weekly:
                return "7"
            
            case .monthly:
                return "30"
        }
    }
    
    static var getPreferredTimeFrameValue: TimeCharts {
        switch SettingsManager.shared.get(key: GlobalSettingKey.selectedTimeframe) ?? PreferredTimeframe.weekly {
            case .daily:
            return .aDay
            
            case .weekly:
            return .aWeek
            
            case .monthly:
            return .aMonth
        }
    }
    
    static var preferredWinnersTimeframe: String {
        switch SettingsManager.shared.get(key: GlobalSettingKey.selectedTimeframe) ?? PreferredTimeframe.weekly {
            case .daily:
                return "Daily Winners"

            case .weekly:
                return "Weekly Winners"

            case .monthly:
                return "Monthly Winners"
        }
    }
    
    static var preferredLosersTimeframe: String {
        switch SettingsManager.shared.get(key: GlobalSettingKey.selectedTimeframe) ?? PreferredTimeframe.weekly {
            case .daily:
                return "Daily Losers"

            case .weekly:
                return "Weekly Losers"

            case .monthly:
                return "Monthly Losers"
        }
    }
    
    var toInputDouble: Double? {
        return Double(self.replacingOccurrences(of: ",", with: "."))
    }
    
    func containsCaseInsensitive(string : String) -> Bool {
        return self.localizedCaseInsensitiveContains(string)
    }
    
    var isNumeric: Bool {
        return !(self.isEmpty) && (self.replacingOccurrences(of: ".", with: "").allSatisfy { $0.isNumber } || self.replacingOccurrences(of: ",", with: "").allSatisfy { $0.isNumber })
    }
    
#if IS_APP
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        
        return size.width
    }
#else
    func widthOfString(usingFont font: UIFont, withDynamicFont: Bool = true) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        
        return size.width
    }
#endif
    
    func heightOfString(usingFont font: UIFont, withDynamicFont: Bool = true) -> CGFloat {
        var dynamicFont = font
        
        if withDynamicFont {
            dynamicFont = UIFontMetrics.default.scaledFont(for: font)
        }

        let fontAttributes = [NSAttributedString.Key.font: dynamicFont]
        let size = self.size(withAttributes: fontAttributes)
        return size.height
    }
    
    func getPriceChangeColor() -> Color {
        return .red
        /*if Double(self) ?? 0 > 0 {
            return Color.mainGreen
        } else if Double(self) ?? 0 < 0 {
            return Color.mainRed
        } else {
            return Color.onSurfaceDim
        }*/
    }
    
    var changeWithSymbol: String {
        let formatter: NumberFormatter = NumberFormatter()
        formatter.locale = Locale.current
        let localizedPlusSign: String = formatter.plusSign
        let localizedMinusSign: String = formatter.minusSign
        let escapedLocalizedPlusSign: String = NSRegularExpression.escapedPattern(
            for: localizedPlusSign
        )
        let escapedLocalizedMinusSign: String = NSRegularExpression.escapedPattern(
            for: localizedMinusSign
        )
        // Currency / FormatStyle output often uses U+2212 MINUS SIGN; Locale.current.minusSign may be ASCII hyphen.
        let escapedUnicodeMinusSign = NSRegularExpression.escapedPattern(for: "\u{2212}")
        let hasNegativeSign: Bool = self.range(
            of: "\(escapedLocalizedMinusSign)|\(escapedUnicodeMinusSign)|-",
            options: .regularExpression
        ) != nil
        let cleaned: String = self.replacingOccurrences(
            of: "\(escapedLocalizedPlusSign)|\(escapedLocalizedMinusSign)|\(escapedUnicodeMinusSign)|\\+|-",
            with: "",
            options: .regularExpression
        )
        if hasNegativeSign {
            return "\(localizedMinusSign)\(cleaned)"
        }
        return "\(localizedPlusSign)\(cleaned)"
    }
    
    var changeWithoutSymbol: String {
        let formatter: NumberFormatter = NumberFormatter()
        formatter.locale = Locale.current
        let localizedPlusSign: String = NSRegularExpression.escapedPattern(
            for: formatter.plusSign
        )
        let localizedMinusSign: String = NSRegularExpression.escapedPattern(
            for: formatter.minusSign
        )
        let escapedUnicodeMinusSign = NSRegularExpression.escapedPattern(for: "\u{2212}")
        let cleaned: String = self.replacingOccurrences(
            of: "\(localizedPlusSign)|\(localizedMinusSign)|\(escapedUnicodeMinusSign)|\\+|-",
            with: "",
            options: .regularExpression
        )
        return cleaned
    }
    
    var withoutSymbol: String {
        return self
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "+", with: "")
    }
    
    func removeZerosFromEnd(maximumDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        let trimmed = self.replacingOccurrences(of: ",", with: ".")
        let number = NSNumber(value: Double(trimmed) ?? 0.0)
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = maximumDigits //maximum digits in Double after dot (maximum precision)
        return String(formatter.string(from: number) ?? "")
    }
    
    func trimmedInput() -> String {
        let array = Array(self)
        var hasColon = false
        var newString = ""
        
        for char in array {
            
            if !hasColon || char != "," {
                newString += String(char)
            }
            
            if char == "," {
                hasColon = true
            }
        }
        
        return newString
    }
    
    static func getStringRandomLength(length: Int) -> String {
        var array = ""
        for _ in (0..<length) {
            array += "0"
        }
        
        return array
    }

    func convertStringToDate(dateFormat: DateFormat, gmtTimeZone: Bool = true) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat.rawValue
        dateFormatter.locale = Locale(identifier: "en-US_POSIX")

        if gmtTimeZone {
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        }
        
        let date = dateFormatter.date(from: self)
        return date
    }
    
    func localizedDescriptionDate(dateStyle: DateFormatter.Style = .long,
                              timeStyle: DateFormatter.Style = .long,
                              in timeZone : TimeZone = .current,
                              locale   : Locale = .current) -> Date? {
        Formatter.date.locale = locale
        Formatter.date.timeZone = timeZone
        Formatter.date.dateStyle = dateStyle
        Formatter.date.timeStyle = timeStyle
        return Formatter.date.date(from: self)
    }

    var localizedDescriptionDate: Date? { localizedDescriptionDate() }

    var symbolAccessible: String {
        self.map({ "\($0) " }).joined()
    }
    
    var intValue: Int {
        return Int(self) ?? 0
    }
    
    func createFile(_ withName: String = "CoinCurrently-Portfolio", extensionName: String = "txt") -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(withName)
            .appendingPathExtension(extensionName)
        let string = self
        try? string.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// Extracts a short display label from a URL for chip display (e.g. "binance.com" or "Twitter")
    var urlDisplayLabel: String {
        let lowercased = self.lowercased()
        if lowercased.contains("twitter.com") || lowercased.contains("x.com") { return "Twitter" }
        if lowercased.contains("reddit.com") { return "Reddit" }
        if lowercased.contains("facebook.com") || lowercased.contains("fb.com") || lowercased.contains("meta") { return "Meta" }
        if lowercased.contains("telegram") || lowercased.contains("t.me") { return "Telegram" }
        if lowercased.contains("github.com") { return "GitHub" }
        if lowercased.contains("bitbucket") { return "Bitbucket" }
        if lowercased.contains("medium.com") { return "Medium" }
        if lowercased.contains("steemit.com") { return "Steemit" }
        if lowercased.contains("discord") { return "Discord" }
        if lowercased.contains("youtube.com") || lowercased.contains("youtu.be") { return "YouTube" }
        guard let url = URL(string: self),
              let host = url.host else { return self }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    func versionCompare(_ otherVersion: String) -> ComparisonResult {
        let versionDelimiter = "."

        var versionComponents = self.components(separatedBy: versionDelimiter)
        var otherVersionComponents = otherVersion.components(separatedBy: versionDelimiter)

        let zeroDiff = versionComponents.count - otherVersionComponents.count

        if zeroDiff == 0 {
            return self.compare(otherVersion, options: .numeric)
        } else {
            let zeros = Array(repeating: "0", count: abs(zeroDiff))
            if zeroDiff > 0 {
                otherVersionComponents.append(contentsOf: zeros)
            } else {
                versionComponents.append(contentsOf: zeros)
            }
            return versionComponents.joined(separator: versionDelimiter)
                .compare(otherVersionComponents.joined(separator: versionDelimiter), options: .numeric)
        }
    }
}
