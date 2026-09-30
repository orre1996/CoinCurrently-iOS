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

    func getNews(coinId: String?) async {
        guard let coinId, !coinId.isEmpty else { return }

        showNewsError = false

        if let news = await newsRepository.getNews(coinId: coinId), !news.isEmpty {
            self.news = news
        } else if self.news.isEmpty {
            showNewsError = true
        }
    }
}
