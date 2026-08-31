//
//  NewsViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-05-25.
//

import Foundation
import Combine

@MainActor
protocol NewsViewModel {
    var news: [NewsItem]? { get }
    var newsVideos: [NewsItem]? { get }
    var podcastNews: [NewsItem]? { get }
    var coinsList: [CoinsListModel] { get }
    var selectedNewsType: NewsType { get }

    func getNews(type: NewsType) async
    func getNewsVideos() async
    func getNewsPodcasts() async
    func getAllCoins() async
}

@MainActor @Observable
final class NewsViewModelImp: NewsViewModel, ObservableObject {
    private(set) var news: [NewsItem]?
    private(set) var newsVideos: [NewsItem]?
    private(set) var podcastNews: [NewsItem]?
    
    private(set) var coinsList = [CoinsListModel]()

    private(set) var selectedNewsType: NewsType = .general
    
    private var cancellable: Set<AnyCancellable> = []
    private var firstVideoLoad = true
        
    private let newsRepository: NewsRepository
    private let globalMarketRepository: GlobalMarketRepository
    private let storeKitManager: StoreKitManager

    init(
        newsRepository: NewsRepository = NewsRepositoryImp.shared,
        globalMarketRepository: GlobalMarketRepository = GlobalMarketRepositoryImp.shared,
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared
    ) {
        self.newsRepository = newsRepository
        self.globalMarketRepository = globalMarketRepository
        self.storeKitManager = storeKitManager
    }
    
    func setStartData() async {
        await newsRepository.ensureCacheLoaded()
        await globalMarketRepository.ensureCacheLoaded()
        
        let selectedType = await newsRepository.selectedNewsType
        self.selectedNewsType = selectedType
        
        if let bigNewsSection = await newsRepository.cachedNews[selectedType]?.data.data {
            self.news = bigNewsSection
            self.filterNews()
        }
        
        if let newsVideos = await newsRepository.cachedNews[.video]?.data.data {
            self.newsVideos = newsVideos
        }
        
        if let newsPodcasts = await newsRepository.cachedNews[.podcasts]?.data.data {
            self.podcastNews = newsPodcasts
        }
    }
    
    func getNews(type: NewsType) async {
        if !type.doesntNeedRefresh(otherType: selectedNewsType) {
            news = nil
        }

        selectedNewsType = type

        let count: Int

        switch type {
            case .general, .neutral, .positive, .negative:
               count = 100

            default:
                count = 25
        }

        await newsRepository.updateNewsType(type)

        if let news = await newsRepository.getNews(type: type, count: count) {
            self.news = news
            filterNews()
        }
    }
    
    func getNewsVideos() async {
        if let news = await newsRepository.getNews(type: .video, count: 25) {
            newsVideos = news
        }
    }
    
    func getNewsPodcasts() async {
        if let news = await newsRepository.getNews(type: .podcasts, count: 25) {
            podcastNews = news
        }
    }

    func getAllCoins() async {
        if let allCoins = await globalMarketRepository.getAllCoins() {
            self.coinsList = allCoins
        }
    }

    private func filterNews() {
        switch selectedNewsType {
            case .positive:
                news = news?.filter({ $0.sentiment == "Positive" })
                
            case .negative:
                news = news?.filter({ $0.sentiment == "Negative" })
                
            case .neutral:
                news = news?.filter({ $0.sentiment == "Neutral" })

            default:
                return
        }
    }
    
    func hasPro() async -> Bool {
        return await storeKitManager.currentSubscription != nil
    }
}
