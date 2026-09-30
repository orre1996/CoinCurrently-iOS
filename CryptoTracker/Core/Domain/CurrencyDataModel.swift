//
//  CurrencyDataModel.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-28.
//

import Foundation
import SwiftUI

struct CurrencyDataModel: Codable, Equatable, Hashable, Identifiable {
    var id: String?
    var symbol: String?
    var name: String?
    var image: Logo?
    var asset_platform_id: String?
    var market_cap_rank: Int?
    var market_data: MarketData?
    var tickers: [Ticker]?
    var description: Description?
    var links: Links?
    var genesis_date: String?
    var sentiment_votes_up_percentage: Double?
    var sentiment_votes_down_percentage: Double?
}

struct Logo: Codable, Hashable, Equatable {
    var thumb: String? = nil
    var small: String? = nil
    var large: String? = nil
}

struct MarketData: Codable, Equatable, Hashable {
    var current_price: [String: Double]?
    var market_cap: [String: Double]?
    var high_24h: [String: Double]?
    var low_24h: [String: Double]?
    var total_volume: [String: Double]?
    var price_change_percentage_24h: Double?
    var price_change_percentage_7d: Double?
    var price_change_percentage_14d: Double?
    var price_change_percentage_30d: Double?
    var price_change_percentage_60d: Double?
    var price_change_percentage_200d: Double?
    var price_change_percentage_1y: Double?
    var sparkline_7d: Sparkline?
    var max_supply: Double?
    var circulating_supply:  Double?
    var ath: [String: Double]?
    var ath_change_percentage: [String: Double]?
    var ath_date: [String: String]?
    var atl: [String: Double]?
    var atl_change_percentage: [String: Double]?
    var atl_date: [String: String]?
    
    func getPreferredChange() -> Double {
        switch SettingsManager.shared.get(key: GlobalSettingKey.selectedTimeframe) ?? PreferredTimeframe.weekly {
            case .daily:
                return price_change_percentage_24h ?? 0.0

            case .weekly:
                return price_change_percentage_7d ?? 0.0

            case .monthly:
                return price_change_percentage_30d ?? 0.0
        }
    }
}

struct Ticker: Codable, Equatable, Hashable {
    var base: String?
    var target: String?
    var market: Market?
    var last: Double?
    var converted_last: [String: Double]?
    var converted_volume: [String: Double]?
    var trust_score: String?
    var trade_url: String?
}

struct Market: Codable, Equatable, Hashable {
    var name: String?
}

struct Description: Codable, Equatable, Hashable {
    var en: String
    var zh: String? = nil
    var zhTw: String? = nil
    var de: String? = nil
    var fr: String? = nil
    var es: String? = nil
    var ja: String? = nil
    var id: String? = nil
    var ru: String? = nil
    var ko: String? = nil
    var ar: String? = nil
    var th: String? = nil
    var vi: String? = nil
    var it: String? = nil
    var pl: String? = nil
    var tr: String? = nil
    var hu: String? = nil
    var nl: String? = nil
    var ro: String? = nil
    var sv: String? = nil
    var cs: String? = nil
    var da: String? = nil
    var el: String? = nil
    var hi: String? = nil
    var no: String? = nil
    var sk: String? = nil
    var uk: String? = nil
    var he: String? = nil
    var fi: String? = nil
    var bg: String? = nil
    var hr: String? = nil
    var lt: String? = nil
    var sl: String? = nil
    var pt: String? = nil

    enum CodingKeys: String, CodingKey {
        case en, zh, de, fr, es, ja, id, ru, ko, ar, th, vi, it, pl, tr, hu, nl, ro, sv, cs, da, el, hi, no, sk, uk, he, fi, bg, hr, lt, sl, pt
        case zhTw = "zh-tw"
    }

    func text(for languageCode: String) -> String {
        let localized = value(for: languageCode)
        if let localized, !localized.isEmpty {
            return localized
        }
        return en
    }

    private func value(for languageCode: String) -> String? {
        switch languageCode {
        case "en": return en
        case "zh": return zh
        case "zh-tw": return zhTw
        case "de": return de
        case "fr": return fr
        case "es": return es
        case "ja": return ja
        case "id": return id
        case "ru": return ru
        case "ko": return ko
        case "ar": return ar
        case "th": return th
        case "vi": return vi
        case "it": return it
        case "pl": return pl
        case "tr": return tr
        case "hu": return hu
        case "nl": return nl
        case "ro": return ro
        case "sv": return sv
        case "cs": return cs
        case "da": return da
        case "el": return el
        case "hi": return hi
        case "no": return no
        case "sk": return sk
        case "uk": return uk
        case "he": return he
        case "fi": return fi
        case "bg": return bg
        case "hr": return hr
        case "lt": return lt
        case "sl": return sl
        case "pt": return pt
        default: return nil
        }
    }
}

struct Links: Codable, Equatable, Hashable {
    var homepage: [String?]?
    var blockchain_site: [String?]?
    var official_forum_url: [String?]?
    var chat_url: [String?]?
    var announcement_url: [String?]?
    var twitter_screen_name: String?
    var facebook_username: String?
    var telegram_channel_identifier: String?
    var subreddit_url: String?
    var whitepaper: String?
    var repos_url: Repos?
    
    var officialWebsites: [String] {
        let homepage = homepage?.compactMap({ $0 }) ?? []
        let forum = official_forum_url?.compactMap({ $0 }) ?? []
        
        return (homepage + forum).filter({ !$0.isEmpty })
    }
    
    var socialMediaUrls: [String] {
        let facebook = facebook_username?.isEmpty ?? true ? nil : "https://facebook.com/\(facebook_username ?? "")"
        let twitter = twitter_screen_name?.isEmpty ?? true ? nil : "https://twitter.com/\(twitter_screen_name ?? "")"
        let telegram = telegram_channel_identifier?.isEmpty ?? true ? nil : "https://t.me\(telegram_channel_identifier ?? "")"
        
        return [subreddit_url, facebook, twitter, telegram].compactMap({ $0 }).filter({ !$0.isEmpty })
    }
    
    var socialMediaIcons: [Image] {
        var icons: [Image] = []
        
        if !(subreddit_url?.isEmpty ?? true) {
            icons.append(.reddit)
        }
        
        if !(facebook_username?.isEmpty ?? true) {
            icons.append(.meta)
        }
        
        if !(twitter_screen_name?.isEmpty ?? true) {
            icons.append(.x)
        }
        
        if !(telegram_channel_identifier?.isEmpty ?? true) {
            icons.append(.telegram)
        }
        
        return icons
    }
    
    var repositoryUrls: [String] {
        let githubUrls = repos_url?.github?.compactMap({ $0 }) ?? []
        let bitbucketUrls = repos_url?.bitbucket?.compactMap({ $0 }) ?? []

        return (githubUrls + bitbucketUrls).filter({ !$0.isEmpty })
    }
    
    var isAllLinksEmpty: Bool {
        return homepage?.allSatisfy({ $0?.isEmpty ?? true }) ?? true &&
        blockchain_site?.allSatisfy({ $0?.isEmpty ?? true }) ?? true &&
        official_forum_url?.allSatisfy({ $0?.isEmpty ?? true }) ?? true &&
        subreddit_url?.isEmpty ?? true &&
        facebook_username?.isEmpty ?? true &&
        twitter_screen_name?.isEmpty ?? true &&
        telegram_channel_identifier?.isEmpty ?? true
    }
}

struct Repos: Codable, Equatable, Hashable {
    var github: [String?]?
    var bitbucket: [String?]?
}

extension CurrencyDataModel {
    func toToplist() -> Toplist {
        return Toplist(
            id: id,
            symbol: symbol,
            name: name,
            image: image?.large,
            current_price: market_data?.current_price?.getConvertedCurrency(),
            market_cap_rank: market_cap_rank,
            sparkline_in_7d: market_data?.sparkline_7d,
            price_change_percentage_24h_in_currency: market_data?.price_change_percentage_24h,
            price_change_percentage_7d_in_currency: market_data?.price_change_percentage_7d,
            price_change_percentage_30d_in_currency: market_data?.price_change_percentage_30d,
            total_volume: market_data?.total_volume?.getConvertedCurrency(),
            market_cap: market_data?.market_cap?.getConvertedCurrency()
        )
    }
}
