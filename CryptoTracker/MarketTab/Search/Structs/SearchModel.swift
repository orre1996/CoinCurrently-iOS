//
//  SearchModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-05-17.
//

import Foundation

struct SearchModel: Codable {
    var coins: [SearchResult]? = nil
    var exchanges: [SearchResult]? = nil
    var categories: [SearchResult]? = nil
    var nfts: [SearchResult]? = nil
    
    var isAllEmpty: Bool {
        return (coins?.isEmpty ?? true) && (exchanges?.isEmpty ?? true) && (nfts?.isEmpty ?? true)
    }
    
    func searchCaseCoins(searchCase: SearchCase) -> [SearchResult] {
        switch searchCase {
        case .onlyCoins, .coins:
            coins?.map({ $0 }) ?? []
        case .nfts:
            nfts?.map({ $0 }) ?? []
        case .categories:
            categories?.map({ $0 }) ?? []
        case .exchanges:
            exchanges?.map({ $0 }) ?? []
        }
    }
}

struct SearchResult: Codable, Hashable {
    var type: String?
    var id: String?
    var name: String?
    var symbol: String?
    var market_cap_rank: Int?
    var thumb: String?
    var large: String?
    
    var toToplistCoin: Toplist {
        return Toplist(
            id: id,
            symbol: symbol,
            name: name,
            image: thumb,
            market_cap_rank: market_cap_rank
        )
    }
    
    var toCryptoDetail: CurrencyDataModel {
        return CurrencyDataModel(
            id: id,
            symbol: symbol,
            name: name,
            image: Logo(
                thumb: thumb,
                small: thumb,
                large: large
            ),
            market_cap_rank: market_cap_rank
        )
    }
    
    var toNft: NFTToplist {
        return NFTToplist(
            id: id,
            name: name,
            image: Logo(
                thumb: thumb,
                small: thumb,
                large: large
            )
        )
    }
    
    var toExchange: Exchange {
        return Exchange(
            id: id,
            name: name,
            image: thumb
        )
    }
    
    var toCategory: CryptoCategory {
        return CryptoCategory(
            id: id,
            name: name
        )
    }
}

struct CategorySearchResult: Codable, Hashable {
    var id: Int?
    var name: String?
}
