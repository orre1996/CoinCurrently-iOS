//
//  NewsType.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-07.
//

import Foundation

enum NewsType: Codable, Hashable {
    case video
    case general
    case neutral
    case positive
    case negative
    case nft
    case podcasts
    case technicalAnalysis
    case coin(symbol: String)
    case exchanges
    case exchange(id: String)
    
    var path: String {
        switch self {
        case .video:
            return "\(serverBaseUrl)/news/api/v1/category?section=alltickers&type=video&page=1"
            
        case .podcasts:
            return "\(serverBaseUrl)/news/api/v1/category?section=alltickers&page=1&topic=podcast"
            
        case .technicalAnalysis:
            return "\(serverBaseUrl)/news/api/v1/category?section=alltickers&page=1&topic=Tanalysis"
            
        case .general, .neutral, .positive, .negative:
            return "\(serverBaseUrl)/news/api/v1/category?section=alltickers&page=1"
            
        case .nft:
            return "\(serverBaseUrl)/news/api/v1/category?section=general&topic=NFT&page=1"
            
        case .coin(let symbol):
            return "\(serverBaseUrl)/news/api/v1?tickers=\(symbol.uppercased())&page=1"
            
        case .exchanges:
            return "\(serverBaseUrl)/news/api/v1/category?section=general&search=exchanges&page=1"
            
        case .exchange(let id):
            return "\(serverBaseUrl)/news/api/v1/category?section=general&search=\(id)&page=1"
        }
    }
    
    var basePath: String {
        switch self {
        case .coin:
            return "\(serverBaseUrl)/news/api/v1"
            
        case .video, .podcasts, .technicalAnalysis, .general, .neutral, .positive, .negative,
                .nft, .exchanges, .exchange:
            return "\(serverBaseUrl)/news/api/v1/category"
        }
    }
    
    var queryItems: [URLQueryItem] {
        switch self {
        case .video:
            return [
                URLQueryItem(name: "section", value: "alltickers"),
                URLQueryItem(name: "type", value: "video"),
                URLQueryItem(name: "page", value: "1")
            ]
            
        case .podcasts:
            return [
                URLQueryItem(name: "section", value: "alltickers"),
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "topic", value: "podcast")
            ]
            
        case .technicalAnalysis:
            return [
                URLQueryItem(name: "section", value: "alltickers"),
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "topic", value: "Tanalysis")
            ]
            
        case .general, .neutral, .positive, .negative:
            return [
                URLQueryItem(name: "section", value: "alltickers"),
                URLQueryItem(name: "page", value: "1")
            ]
            
        case .nft:
            return [
                URLQueryItem(name: "section", value: "general"),
                URLQueryItem(name: "topic", value: "NFT"),
                URLQueryItem(name: "page", value: "1")
            ]
            
        case .coin(let id):
            return [
                URLQueryItem(name: "tickers", value: id.uppercased()),
                URLQueryItem(name: "page", value: "1")
            ]
            
        case .exchanges:
            return [
                URLQueryItem(name: "section", value: "general"),
                URLQueryItem(name: "search", value: "exchanges"),
                URLQueryItem(name: "page", value: "1")
            ]
            
        case .exchange(let id):
            return [
                URLQueryItem(name: "section", value: "general"),
                URLQueryItem(name: "search", value: id),
                URLQueryItem(name: "page", value: "1")
            ]
        }
    }
    
    func doesntNeedRefresh(otherType: NewsType) -> Bool {
        return (self == .general || self == .positive || self == .neutral || self == .negative) &&
            (otherType == .general || otherType == .positive || otherType == .neutral || otherType == .negative)
    }
    
    var cacheKey: String {
        switch self {
        case .video:
            return "video"
            
        case .podcasts:
            return "podcasts"
            
        case .technicalAnalysis:
            return "technicalAnalysis"
            
        case .general, .positive, .negative, .neutral:
            return "general"
            
        case .nft:
            return "nft"
            
        case .coin(let id):
            return "coin-\(id)"
            
        case .exchanges:
            return "exchanges"
            
        case .exchange(let id):
            return "exchange-\(id)"
        }
    }
    
    var toCarouselFilter: CarouselFilter {
        switch self {
        case .video:
            .general
        case .general:
            .general
        case .neutral:
            .neutral
        case .positive:
            .positive
        case .negative:
            .negative
        case .nft:
            .nfts
        case .podcasts:
            .general
        case .technicalAnalysis:
            .technicalAnalysis
        case .coin(let id):
            .coins(id)
        case .exchange(let id):
            .exchanges(id)
        case .exchanges:
            .exchanges("")
        }
    }
    
    var selectedId: String {
        switch self {
        case .coin(let id), .exchange(let id):
            return id
        default:
            return ""
        }
    }
}
