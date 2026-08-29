//
//  NewsWidgetCategory.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 6/19/26.
//

import AppIntents
import Foundation

enum NewsWidgetCategory: String, AppEnum {
    case general
    case positive
    case neutral
    case negative
    case exchanges
    case nfts
    case technicalAnalysis
    case bitcoin
    case ethereum
    case xrp
    case sol

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Category")

    static let caseDisplayRepresentations: [NewsWidgetCategory: DisplayRepresentation] = [
        .general: "General",
        .positive: "Positive",
        .neutral: "Neutral",
        .negative: "Negative",
        .exchanges: "Exchanges (Pro)",
        .nfts: "NFTs (Pro)",
        .technicalAnalysis: "Technical Analysis (Pro)",
        .bitcoin: "Bitcoin (Pro)",
        .ethereum: "Ethereum (Pro)",
        .xrp: "XRP (Pro)",
        .sol: "SOL (Pro)"
    ]

    var requiresPro: Bool {
        switch self {
        case .exchanges, .nfts, .technicalAnalysis, .bitcoin, .ethereum, .xrp, .sol:
            return true
        default:
            return false
        }
    }

    func toNewsType() async -> NewsType {
        switch self {
        case .general:
            return .general
        case .positive:
            return .positive
        case .neutral:
            return .neutral
        case .negative:
            return .negative
        case .exchanges:
            return .exchanges
        case .nfts:
            return .nft
        case .technicalAnalysis:
            return .technicalAnalysis
        case .bitcoin:
            return .coin(symbol: "BTC")
        case .ethereum:
            return .coin(symbol: "ETH")
        case .xrp:
            return .coin(symbol: "XRP")
        case .sol:
            return .coin(symbol: "SOL")
        }
    }
}

enum NewsWidgetCategoryResolver {
    static func resolvedNewsType(for category: NewsWidgetCategory = .general) async -> NewsType {
        if category.requiresPro, !(await WidgetProAccess.hasPro()) {
            return .general
        }

        return await category.toNewsType()
    }

    static func filteredNews(_ news: [NewsItem], for type: NewsType) -> [NewsItem] {
        switch type {
        case .positive:
            return news.filter { $0.sentiment == "Positive" }
        case .negative:
            return news.filter { $0.sentiment == "Negative" }
        case .neutral:
            return news.filter { $0.sentiment == "Neutral" }
        default:
            return news
        }
    }

    static func fetchCount(for type: NewsType, itemCount: Int) -> Int {
        switch type {
        case .general, .neutral, .positive, .negative:
            return 100
        default:
            return max(itemCount, 25)
        }
    }
}
