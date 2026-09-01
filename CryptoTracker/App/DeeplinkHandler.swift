//
//  DeeplinkHandler.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/25/25.
//

import Foundation

enum DeeplinkHandler {
    case buyPro
    case home
    case portfolio
    case marketTab
    case news
    case settings
    case fearGreed
    case priceAlerts
    case globalMarket
    case gasFees
    case market(url: URL)
    case feedback
    case cryptoDetail(id: String, symbol: String)
    case referral(code: String)
    case web(url: String)
    case none
    
    static func referralCode(from url: String) -> String? {
        guard let parsedURL = URL(string: url),
              let host = parsedURL.host?.lowercased(),
              host == "coincurrently.app" || host.hasSuffix(".coincurrently.app") else {
            return nil
        }
        
        let pathComponents = parsedURL.pathComponents.filter { $0 != "/" }
        guard pathComponents.count >= 2,
              pathComponents[0].lowercased() == "invite" else {
            return nil
        }
        
        let code = pathComponents[1].trimmingCharacters(in: .whitespacesAndNewlines)
        return code.isEmpty ? nil : code
    }
    
    static func getLink(url: String) -> DeeplinkHandler {
        if url == "buyPro" {
            return .buyPro
        } else if url == "home" {
            return .home
        } else if url == "portfolio" {
            return .portfolio
        } else if url == "marketTab" {
            return .marketTab
        } else if url == "news" {
            return .news
        } else if url == "settings" {
            return .settings
        } else if url == "market", let webUrl = URL(string: "https://apps.apple.com/se/app/coincurrently/id1543974454#?platform=iphone") {
            return .market(url: webUrl)
        } else if url == "fearGreed" {
            return .fearGreed
        } else if url == "priceAlerts" {
            return .priceAlerts
        } else if url == "globalMarket" {
            return .globalMarket
        } else if url == "gasFees" {
            return .gasFees
        } else if url == "feedback" {
            return .feedback
        } else if let code = referralCode(from: url) {
            return .referral(code: code)
        } else if url.lowercased().contains("www.") || url.lowercased().contains("https") {
            return .web(url: url)
        } else if let id = url.split(separator: ",").first, let symbol = url.split(separator: ",").last {
            return .cryptoDetail(id: String(id), symbol: String(symbol))
        } else {
            return .none
        }
    }
}
