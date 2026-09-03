//
//  CryptoDetailNewsViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/2/26.
//

import Foundation

@MainActor
@Observable
final class CryptoDetailNewsViewModel {
    var news = [NewsItem]()
    var showNewsError = false

    private let newsRepository: NewsRepository

    init(newsRepository: NewsRepository = NewsRepositoryImp.shared) {
        self.newsRepository = newsRepository
    }

    func loadCached(symbol: String?) async {
        guard let symbol = symbol?.uppercased() else {
            news = []
            return
        }

        if let newsData = await newsRepository.cachedNews[.coin(symbol: symbol)]?.data.data {
            news = newsData
        } else {
            news = []
        }
    }

    func getNews(symbol: String?) async {
        guard let id = symbol?.uppercased() else { return }

        showNewsError = false
        await loadCached(symbol: id)

        if let news = await newsRepository.getNews(type: .coin(symbol: id), count: 25), !news.isEmpty {
            self.news = news
        } else if self.news.isEmpty {
            showNewsError = true
        }
    }
}
