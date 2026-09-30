//
//  NewsViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-05-25.
//

import Foundation

@MainActor
protocol NewsViewModel {
    var news: [NewsItem]? { get }
    func getNews() async
}

@MainActor @Observable
final class NewsViewModelImp: NewsViewModel {
    private(set) var news: [NewsItem]?

    private let newsRepository: NewsRepository

    init(newsRepository: NewsRepository = NewsRepositoryImp.shared) {
        self.newsRepository = newsRepository
    }

    func getNews() async {
        if let news = await newsRepository.getNews(coinId: nil) {
            self.news = news
        }
    }
}
