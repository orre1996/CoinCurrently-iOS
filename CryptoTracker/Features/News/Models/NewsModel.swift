//
//  NewsModel.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-31.
//

import Foundation

struct NewsItem: Codable, Equatable, Hashable {
    var title: String? = nil
    var url: String? = nil
    var image: String? = nil
    var author: String? = nil
    var posted_at: String? = nil
    var articleType: String? = nil
    var source_name: String? = nil
    var related_coin_ids: [String]? = nil
    var relatedCoinNames: [String] = []

    enum CodingKeys: String, CodingKey {
        case title, url, image, author, posted_at, source_name, related_coin_ids
        case articleType = "type"
    }

    var news_url: String? { url }
    var image_url: String? { image }

    var publishedDate: Date? {
        guard let posted_at else { return nil }
        return ISO8601DateFormatter().date(from: posted_at)
    }
}

enum CoinGeckoNewsLanguage {
    private static let supported: Set<String> = [
        "en", "ru", "de", "pl", "es", "vi", "fr", "pt-br", "ar", "bg", "cs", "da",
        "el", "fi", "he", "hi", "hr", "hu", "id", "it", "ja", "ko", "lt", "nl", "no",
        "ro", "sk", "sl", "sv", "th", "tr", "uk", "zh", "zh-tw"
    ]

    static var code: String {
        let stored: String? = SettingsManager.shared.get(key: AppSettingKey.selectedLanguage)
        let raw: String
        switch stored {
        case .none, "", "system":
            raw = systemCode
        case "pt":
            raw = "pt-br"
        default:
            raw = stored ?? "en"
        }
        return supported.contains(raw) ? raw : "en"
    }

    private static var systemCode: String {
        for identifier in Locale.preferredLanguages {
            let normalized = identifier.replacingOccurrences(of: "_", with: "-").lowercased()
            if normalized.hasPrefix("zh") {
                if normalized.contains("hant")
                    || normalized.contains("-tw")
                    || normalized.contains("-hk")
                    || normalized.contains("-mo") {
                    return "zh-tw"
                }
                return "zh"
            }
            if normalized.hasPrefix("pt") { return "pt-br" }
            if normalized.hasPrefix("no") || normalized.hasPrefix("nb") || normalized.hasPrefix("nn") {
                return "no"
            }
            let code = normalized.split(separator: "-").first.map(String.init) ?? normalized
            if supported.contains(code) { return code }
        }
        return "en"
    }
}
