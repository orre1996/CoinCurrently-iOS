//
//  NewsRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-16.
//

import Foundation

protocol NewsRepository: Actor {
    func getNews(coinId: String?) async -> [NewsItem]?
}

final actor NewsRepositoryImp: NewsRepository {
    static let shared = NewsRepositoryImp()

    private let networkManager: NetworkManager

    init(networkManager: NetworkManager = NetworkManagerImp.shared) {
        self.networkManager = networkManager
    }

    func getNews(coinId: String?) async -> [NewsItem]? {
        let items: [NewsItem]? = await networkManager.get(
            endpoint: .news(coinId: coinId, language: CoinGeckoNewsLanguage.code)
        )
        guard let items else { return nil }

        let coins: [CoinsListModel]? = await networkManager.get(endpoint: .allCoins)
        var namesById: [String: String] = [:]
        for coin in coins ?? [] {
            guard let id = coin.id, let name = coin.name, !name.isEmpty, namesById[id] == nil else { continue }
            namesById[id] = name
        }

        return items.map { item in
            var copy = item
            copy.source_name = item.source_name?.strippingParentheticalNotes()
            copy.author = item.author?.strippingParentheticalNotes()
            copy.relatedCoinNames = (item.related_coin_ids ?? []).compactMap { namesById[$0] }
            return copy
        }
    }
}

private extension String {
    /// Drops parenthetical notes such as " (Sweden)" or " (svenska)" from a news source name.
    func strippingParentheticalNotes() -> String {
        let stripped = replacingOccurrences(
            of: "\\s*\\([^)]*\\)",
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        return stripped.isEmpty ? trimmingCharacters(in: .whitespacesAndNewlines) : stripped
    }
}
