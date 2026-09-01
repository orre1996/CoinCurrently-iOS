//
//  Date+Extensions.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-23.
//

import Foundation

extension Formatter {
    static let date = DateFormatter()
}

extension Date {
    var fullDate: String   { localizedDescription(dateStyle: .full,   timeStyle: .none) }
    var longDate: String   { localizedDescription(dateStyle: .long,   timeStyle: .none) }
    var mediumDate: String { localizedDescription(dateStyle: .medium, timeStyle: .none) }
    var shortDate: String  { localizedDescription(dateStyle: .short,  timeStyle: .none) }
    
    var fullTime: String   { localizedDescription(dateStyle: .none,   timeStyle: .full) }
    var longTime: String   { localizedDescription(dateStyle: .none,   timeStyle: .long) }
    var mediumTime: String { localizedDescription(dateStyle: .none,   timeStyle: .medium) }
    var shortTime: String  { localizedDescription(dateStyle: .none,   timeStyle: .short) }
    
    var fullDateTime: String   { localizedDescription(dateStyle: .full,   timeStyle: .full) }
    var longDateTime: String   { localizedDescription(dateStyle: .long,   timeStyle: .long) }
    var mediumDateTime: String { localizedDescription(dateStyle: .medium, timeStyle: .medium) }
    var shortDateTime: String  { localizedDescription(dateStyle: .short,  timeStyle: .short) }
    
    var portfolioExportDateTimeUTC: String {
        Self.portfolioExportDateFormatter.string(from: self)
    }
    
    var coinTrackerExportDateTimeUTC: String {
        Self.coinTrackerExportDateFormatter.string(from: self)
    }
    
    private static let portfolioExportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    private static let coinTrackerExportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
        return formatter
    }()
    
    var addedAccessibilityDescription: String {
        "Added \(formatted(.dateTime.weekday(.wide).month(.wide).day().year().hour().minute()))"
    }
    
    static var uses24HourClock: Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("j")

        let dateFormat = formatter.dateFormat
        return !(dateFormat?.contains("a") ?? false)
    }
    
    var localizedDescription: String { localizedDescription() }
    
    var timeAgoDisplay: String {
        let calendar = Calendar.current
        let minuteAgo = calendar.date(byAdding: .minute, value: -1, to: Date())!
        let hourAgo = calendar.date(byAdding: .hour, value: -1, to: Date())!
        let dayAgo = calendar.date(byAdding: .day, value: -1, to: Date())!
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        if minuteAgo < self {
            let diff = Calendar.current.dateComponents([.second], from: self, to: Date()).second ?? 0
            return diff == 1 ? "\(diff) second ago" : "\(diff) seconds ago"
        } else if hourAgo < self {
            let diff = Calendar.current.dateComponents([.minute], from: self, to: Date()).minute ?? 0
            return diff == 1 ? "\(diff) minute ago" : "\(diff) minutes ago"
        } else if dayAgo < self {
            let diff = Calendar.current.dateComponents([.hour], from: self, to: Date()).hour ?? 0
            return diff == 1 ? "\(diff) hour ago" : "\(diff) hours ago"
        } else if weekAgo < self {
            let diff = Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
            return diff == 1 ? "\(diff) day ago" : "\(diff) days ago"
        }
        let diff = Calendar.current.dateComponents([.weekOfYear], from: self, to: Date()).weekOfYear ?? 0
        return diff == 1 ? "\(diff) week ago" : "\(diff) weeks ago"
    }
    
    var alertTimeAgoDisplay: String {
        let calendar = Calendar.current
        let minuteAgo = calendar.date(byAdding: .minute, value: -1, to: Date())!
        let hourAgo = calendar.date(byAdding: .hour, value: -1, to: Date())!
        let dayAgo = calendar.date(byAdding: .day, value: -1, to: Date())!
        
        if minuteAgo < self {
            return "just now"
        } else if hourAgo < self {
            let diff = Calendar.current.dateComponents([.minute], from: self, to: Date()).minute ?? 0
            return diff == 1 ? "\(diff) minute ago" : "\(diff) minutes ago"
        } else if dayAgo < self {
            let diff = Calendar.current.dateComponents([.hour], from: self, to: Date()).hour ?? 0
            return diff == 1 ? "\(diff) hour ago" : "\(diff) hours ago"
        } else {
            return self.formatted(date: .long, time: .omitted)
        }
    }
    
    var daysAgo: String {
        let diff = Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
        let formattedDiff = diff.formatted(.number)
        return diff == 1 ? "\(formattedDiff) day" : "\(formattedDiff) days"
    }
    
    var nearestHour: Date {
        var components = NSCalendar.current.dateComponents([.minute], from: self)
        let minute = components.minute ?? 0
        components.minute = minute >= 30 ? 60 - minute : -minute
        return Calendar.current.date(byAdding: components, to: self) ?? Date()
    }
    
    static var moreThanADay: TimeInterval {
        return  60 * 60 * 24
    }
    
    func defaultCacheTimer(hasBoughtPro: Bool) -> Bool {
        return (Date().timeIntervalSince(self) > 60 * Double(Date.cacheTime(hasBoughtPro: hasBoughtPro)))
    }
    
    func moreThanSixtyMinutesAgo() -> Bool {
        return (Date().timeIntervalSince(self) > 60 * 60)
    }
    
    func moreThanTwoDays() -> Bool {
        return (Date().timeIntervalSince(self) > 60 * 60 * 24 * 2)
    }
    
    func moreThanAMonth() -> Bool {
        return (Date().timeIntervalSince(self) > 60 * 60 * 24 * 30)
    }
    
    static var tenYearsAgo: Date {
        return Date(timeIntervalSinceNow: -60 * 60 * 24 * 365 * 10)
    }
    
    static var fiftyYearsAgo: Date {
        return Date(timeIntervalSinceNow: -60 * 60 * 24 * 365 * 50)
    }
    
    func zeroMinutesAndSeconds(using calendar: Calendar = .current) -> Date {
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: self)
        return calendar.date(from: components) ?? self
    }
    
    func localizedDescription(
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .medium,
        in timeZone : TimeZone = .current,
        locale: Locale = .current
    ) -> String {
        Formatter.date.locale = locale
        Formatter.date.timeZone = timeZone
        Formatter.date.dateStyle = dateStyle
        Formatter.date.timeStyle = timeStyle
        return Formatter.date.string(from: self)
    }
    
    func setTime(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0, timeZoneAbbrev: String = "GMT") -> Date? {
        let x: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let cal = Calendar.current
        var components = cal.dateComponents(x, from: self)

        components.timeZone = TimeZone(abbreviation: timeZoneAbbrev)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0

        return cal.date(from: components)
    }
    
    static func futureDate(byAddingDays days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }
    
    static func cacheTime(hasBoughtPro: Bool) -> Int {
#if IS_WIDGET
        return 0
#else
        return hasBoughtPro ? 3 : 15
#endif
    }
    
    func accessibleChartHoverDate(
        timeChart: TimeCharts,
        dontShowTime: Bool = false,
        useExchangeFormat: Bool = false
    ) -> String {
        if useExchangeFormat {
            return accessibleChartExchangeHoverDate(timeChart: timeChart)
        }
        
        switch timeChart {
        case .aWeek:
            if dontShowTime {
                return formatted(.dateTime.month(.wide).day().year())
            }
            return "\(formatted(.dateTime.month(.wide).day())) at \(accessibleChartHoverTime)"
        case .aMonth, .threeMonths, .aYear:
            return formatted(.dateTime.month(.wide).day().year())
        case .max:
            return formatted(.dateTime.month(.wide).day().year())
        default:
            return "\(formatted(.dateTime.month(.wide).day())) at \(accessibleChartHoverTime)"
        }
    }
    
    private func accessibleChartExchangeHoverDate(timeChart: TimeCharts) -> String {
        switch timeChart {
        case .aDay, .aWeek:
            return "\(formatted(.dateTime.month(.wide).day())) at \(accessibleChartHoverTime)"
        case .aMonth, .aYear:
            return formatted(.dateTime.month(.wide).day().year())
        case .max:
            return formatted(.dateTime.month(.wide).day().year())
        default:
            return "\(formatted(.dateTime.day().month(.wide))) at \(accessibleChartHoverTime)"
        }
    }
    
    private var accessibleChartHoverTime: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: self)
        let minute = calendar.component(.minute, from: self)
        
        if Date.uses24HourClock {
            if minute == 0 {
                if hour == 0 {
                    return "midnight"
                }
                return "\(Double(hour).numberAccessible(maxPlaces: 0)) o'clock"
            }
            
            if hour == 0 {
                return "\(Double(minute).numberAccessible(maxPlaces: 0)) past midnight"
            }
            
            return "\(Double(hour).numberAccessible(maxPlaces: 0)) \(accessibleSpokenMinute(minute))"
        }
        
        let hour12 = hour % 12
        let displayHour = hour12 == 0 ? 12 : hour12
        let period = hour < 12 ? "am" : "pm"
        
        if minute == 0 {
            return "\(Double(displayHour).numberAccessible(maxPlaces: 0)) \(period)"
        }
        
        return "\(Double(displayHour).numberAccessible(maxPlaces: 0)) \(accessibleSpokenMinute(minute)) \(period)"
    }
    
    private func accessibleSpokenMinute(_ minute: Int) -> String {
        if minute < 10 {
            return "oh \(Double(minute).numberAccessible(maxPlaces: 0))"
        }
        
        return Double(minute).numberAccessible(maxPlaces: 0)
    }
}
