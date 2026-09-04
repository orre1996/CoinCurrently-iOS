//
//  Numeric+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-01-15.
//

import Foundation

extension Numeric {
    var formattedWithPortfolioAmount: String { Formatter.withSeparatorPortfolioAmount.string(for: self) ?? "" }
}

extension DateFormatter {
    static let iso8601DateFormatter: DateFormatter = {
        let enUSPOSIXLocale = Locale(identifier: "en_US_POSIX")
        let iso8601DateFormatter = DateFormatter()
        iso8601DateFormatter.locale = enUSPOSIXLocale
        iso8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        iso8601DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return iso8601DateFormatter
    }()

    static let iso8601WithoutMillisecondsDateFormatter: DateFormatter = {
        let enUSPOSIXLocale = Locale(identifier: "en_US_POSIX")
        let iso8601DateFormatter = DateFormatter()
        iso8601DateFormatter.locale = enUSPOSIXLocale
        iso8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        iso8601DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return iso8601DateFormatter
    }()

    static func date(fromISO8601String string: String) -> Date? {
        if let dateWithMilliseconds = iso8601DateFormatter.date(from: string) {
            return dateWithMilliseconds
        }
        
        if let dateWithoutMilliseconds = iso8601WithoutMillisecondsDateFormatter.date(from: string) {
            return dateWithoutMilliseconds
        }
        
        return nil
    }
}
