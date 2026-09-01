//
//  TrendingRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-15.
//

import Foundation
import Combine

protocol TrendingRepository: Actor {
    var cachedTrending: CachedData<TrendingItems>? { get }
    var cachedTrendingCoins: CachedData<[Toplist]>? { get }
    
    func ensureCacheLoaded() async
    func getTrendingCoins() async -> [Toplist]?
    func getTrendingList() async -> TrendingItems?
    func updateFromToplist(coins: [Toplist])
}

final actor TrendingRepositoryImp: TrendingRepository {
    static let shared = TrendingRepositoryImp()

    private(set) var cachedTrending: CachedData<TrendingItems>?
    private(set) var cachedTrendingCoins: CachedData<[Toplist]>?

    private let networkManager: NetworkManager
    private let priceAlertRepository: PriceAlertsRepository

    init(
        networkManager: NetworkManager = NetworkManagerImp.shared,
        priceAlertRepository: PriceAlertsRepository = PriceAlertsRepositoryImp.shared
    ) {
        self.networkManager = networkManager
        self.priceAlertRepository = priceAlertRepository
        
        self.cachedTrending = nil
        self.cachedTrendingCoins = nil
    }
    
    private var hasLoadedFromStorage = false
    
    func ensureCacheLoaded() async {
        guard !hasLoadedFromStorage else { return }
        hasLoadedFromStorage = true
        if let trending: TrendingItems = await networkManager.getCached(endpoint: .trending) {
            cachedTrending = CachedData(data: trending, date: Date())
            let ids = trending.coins?.compactMap { $0.item?.id } ?? []
            if !ids.isEmpty {
                let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
                if let coins: [Toplist] = await networkManager.getCached(
                    endpoint: .multipleCoins(ids: ids, currency: currency)
                ) {
                    cachedTrendingCoins = CachedData(data: coins, date: Date())
                }
            }
        }
    }

    func getTrendingCoins() async -> [Toplist]? {
        await ensureCacheLoaded()
        guard let trendingCoins = await getTrendingList()?.coins else {
            return nil
        }
        
        let ids = trendingCoins.compactMap { $0.item?.id }
        guard !ids.isEmpty else { return nil }
        
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        let coins: [Toplist]? = await networkManager.get(
            endpoint: .multipleCoins(ids: ids, currency: currency)
        )
        
        if let coins {
            cachedTrendingCoins = CachedData(data: coins, date: Date())
            await ToplistRepositoryImp.shared.updateFromToplist(coins: coins)
            await NewCoinsRepositoryImp.shared.updateFromToplist(coins: coins)
            await WinnersLosersRepositoryImp.shared.updateFromToplist(coins: coins)
        }
        
        return coins
    }
    
    func getTrendingList() async -> TrendingItems? {
        await ensureCacheLoaded()
        let trendingItems: TrendingItems? = await networkManager.get(endpoint: .trending)

        if let trendingItems {
            cachedTrending = CachedData(data: trendingItems, date: Date())
        }
        
        return trendingItems
    }
    
    func updateFromToplist(coins: [Toplist]) {
        guard let trendingList = cachedTrendingCoins?.data, !coins.isEmpty else { return }

        trendingList.enumerated().forEach { index, trending in
            if let coinIndex = coins.firstIndex(where: { $0.id == trending.id }) {
                cachedTrendingCoins?.data[index] = coins[coinIndex]
            }
        }
    }
    
}

