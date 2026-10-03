//
//  NewsRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-16.
//

import Foundation

protocol NewsRepository: Actor {
    var selectedNewsType: NewsType { get }
    var cachedNews: [NewsType: CachedData<NewsModel>] { get }
    
    func ensureCacheLoaded() async
    func getNews(type: NewsType, count: Int) async -> [NewsItem]?
    func updateNewsType(_ type: NewsType) async
}

final actor NewsRepositoryImp: NewsRepository {
    static let shared = NewsRepositoryImp()

    private let networkManager: NetworkManager
    private let settingsManager: SettingsManager
    private var hasLoadedFromStorage = false

    private(set) var selectedNewsType: NewsType
    private(set) var cachedNews: [NewsType: CachedData<NewsModel>]
    
    init(
        networkManager: NetworkManager = NetworkManagerImp.shared,
        settingsManager: SettingsManager = SettingsManager.shared
    ) {
        self.networkManager = networkManager
        self.settingsManager = settingsManager
        self.cachedNews = [:]
        self.selectedNewsType = settingsManager.get(key: NewsSettingKey.lastNewsCategory) ?? .general
    }

    func ensureCacheLoaded() async {
        guard !hasLoadedFromStorage else { return }
        hasLoadedFromStorage = true
        for type in [NewsType.general, .video, .neutral, .positive, .negative, .nft, .podcasts, .technicalAnalysis, .exchanges] {
            if let news: NewsModel = await networkManager.getCached(endpoint: .news(type: type, count: count(for: type))) {
                cachedNews[type] = CachedData(data: news, date: Date())
            }
        }
    }

    func getNews(type: NewsType, count: Int) async -> [NewsItem]? {
        await ensureCacheLoaded()
        let news: NewsModel? = await networkManager.get(endpoint: .news(type: type, count: count))
        
        if let news {
            cachedNews[type] = CachedData(data: news, date: Date())
        }

        return news?.data
    }
    
    func updateNewsType(_ type: NewsType) async {
        selectedNewsType = type
        settingsManager.set(data: selectedNewsType, key: NewsSettingKey.lastNewsCategory)
    }

    private func count(for type: NewsType) -> Int {
        switch type {
        case .general, .neutral, .positive, .negative:
            return 100
        default:
            return 25
        }
    }

}
