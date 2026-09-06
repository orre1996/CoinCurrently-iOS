//
//  ToplistRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-10.
//

import Foundation
import Combine

protocol ToplistRepository: Actor {
    var cachedFavorites: CachedData<[Toplist]>? { get }
    var cachedSmallToplist: CachedData<[Toplist]>? { get }
    var cachedToplist: [String: CachedData<[Toplist]>] { get }
    
    func ensureCacheLoaded() async
    func ensureFavoritesLoaded() async
    func migrateFavorites() async
    func getSmallToplist() async -> [Toplist]?
    func getMarketToplist(sortOption: SortOption, priceChange: PriceChange, platformId: String?) async -> [Toplist]?
    func getFavorites() async -> [Toplist]?
    func favouriteButtonPressed(toplist: Toplist) async -> [Toplist]
    func updateFromToplist(coins: [Toplist]) async
    func refreshForCurrencyChange(sortOption: SortOption, priceChange: PriceChange) async
    func getCoin(id: String) async -> Toplist?
}

final actor ToplistRepositoryImp: ToplistRepository {
    static let shared = ToplistRepositoryImp()
    
    private let networkManager: NetworkManager
    private let winnersLosersRepository: WinnersLosersRepository
    private let coreDataManager: CoreDataManager
    
    var cachedFavorites: CachedData<[Toplist]>?
    private(set) var cachedSmallToplist: CachedData<[Toplist]>?
    private(set) var cachedToplist: [String: CachedData<[Toplist]>] = [:]

    init(
        networkManager: NetworkManager = NetworkManagerImp.shared,
        winnersLosersRepository: WinnersLosersRepository = WinnersLosersRepositoryImp.shared,
        coreDataManager: CoreDataManager = CoreDataManager.shared
    ) {
        self.networkManager = networkManager
        self.winnersLosersRepository = winnersLosersRepository
        self.coreDataManager = coreDataManager
        
        self.cachedFavorites = CachedData(data: [], date: Date.tenYearsAgo)
    }
    
    private var hasLoadedFromStorage = false
    private var hasLoadedFavoritesFromStorage = false
    
    func ensureFavoritesLoaded() async {
        guard !hasLoadedFavoritesFromStorage else { return }
        hasLoadedFavoritesFromStorage = true
        cachedFavorites = await coreDataManager.get(forKey: .favorites) ?? CachedData(data: [], date: Date.tenYearsAgo)
    }
    
    func ensureCacheLoaded() async {
        await ensureFavoritesLoaded()
        guard !hasLoadedFromStorage else { return }
        hasLoadedFromStorage = true
        
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        
        if let small: [Toplist] = await networkManager.getCached(
            endpoint: .toplist(itemsPerPage: 25, sortOption: .mktCapDesc, currency: currency, platformId: nil)
        ) {
            cachedSmallToplist = CachedData(data: small, date: Date())
        }
        
        await winnersLosersRepository.ensureCacheLoaded()
        
        let selectedSortOption: SortOption = SettingsManager.shared.get(key: AppSettingKey.toplistSortOption) ?? .mktCapDesc
        let selectedPriceChangeOption: PriceChange = SettingsManager.shared.get(key: AppSettingKey.toplistPriceChange) ?? .sevenDays
        
        if selectedSortOption == .priceChangeDesc || selectedSortOption == .priceChangeAsc {
            if let winners: [Toplist] = await winnersLosersRepository.cachedWinnersCoins[selectedPriceChangeOption.rawValue]?.data {
                let key = "\(SortOption.priceChangeDesc.getOptionKey(priceChange: selectedPriceChangeOption))-"
                cachedToplist[key] = CachedData(data: winners, date: Date())
            }
            if let losers: [Toplist] = await winnersLosersRepository.cachedLosersCoins[selectedPriceChangeOption.rawValue]?.data {
                let key = "\(SortOption.priceChangeAsc.getOptionKey(priceChange: selectedPriceChangeOption))-"
                cachedToplist[key] = CachedData(data: losers, date: Date())
            }
        } else if let market: [Toplist] = await networkManager.getCached(
            endpoint: .toplist(itemsPerPage: 250, sortOption: selectedSortOption, currency: currency, platformId: nil)
        ) {
            let marketKey = "\(selectedSortOption.getOptionKey(priceChange: selectedPriceChangeOption))-"
            cachedToplist[SortOption.mktCapDesc.toplistApiValue] = CachedData(data: market, date: Date())
            cachedToplist[marketKey] = CachedData(data: market, date: Date())
        }
        
        for priceChange in PriceChange.allCases {
            if let winners: [Toplist] = await winnersLosersRepository.cachedWinnersCoins[priceChange.rawValue]?.data {
                let key = "\(SortOption.priceChangeDesc.getOptionKey(priceChange: priceChange))-"
                cachedToplist[key] = CachedData(data: winners, date: Date())
            }
            if let losers: [Toplist] = await winnersLosersRepository.cachedLosersCoins[priceChange.rawValue]?.data {
                let key = "\(SortOption.priceChangeAsc.getOptionKey(priceChange: priceChange))-"
                cachedToplist[key] = CachedData(data: losers, date: Date())
            }
        }
    }
    
    func migrateFavorites() async {
        let favorites: CachedData<[Toplist]>? = await CachedStorageManagerImp.shared.load(type: LocalStorageKeys.favorites)
        let containsCoreDataFavorites: Bool = await coreDataManager.contains(key: .favorites)

        guard let favorites, !favorites.data.isEmpty, !containsCoreDataFavorites else {
            return
        }

        await coreDataManager.set(favorites, forKey: .favorites)
    }
    
    func getSmallToplist() async -> [Toplist]? {
        await ensureCacheLoaded()
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        guard let toplist: [Toplist] = await networkManager.get(
            endpoint: .toplist(
                itemsPerPage: 25,
                sortOption: .mktCapDesc,
                currency: currency
            )
        ) else {
            return nil
        }
        
        cachedSmallToplist = CachedData(data: toplist, date: Date())
        
        await TrendingRepositoryImp.shared.updateFromToplist(coins: toplist)
        await NewCoinsRepositoryImp.shared.updateFromToplist(coins: toplist)
        await WinnersLosersRepositoryImp.shared.updateFromToplist(coins: toplist)
        await updateFromToplist(coins: toplist)

        return toplist
    }
    
    func getMarketToplist(sortOption: SortOption, priceChange: PriceChange, platformId: String?) async -> [Toplist]? {
        await ensureCacheLoaded()
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        let toplist: [Toplist]?
        
        if sortOption == .priceChangeDesc {
            toplist = await winnersLosersRepository.getWinners(priceChange: priceChange)
        } else if sortOption == .priceChangeAsc {
            toplist = await winnersLosersRepository.getLosers(priceChange: priceChange)
        } else {
            toplist = await networkManager.get(
                endpoint: .toplist(
                    itemsPerPage: 250,
                    sortOption: sortOption,
                    currency: currency,
                    platformId: platformId
                )
            )
        }
        
        guard let toplist else {
            return nil
        }
        
        let cacheKey = "\(sortOption.getOptionKey(priceChange: priceChange))-\(platformId ?? "")"
        cachedToplist[cacheKey] = CachedData(data: toplist, date: Date())
        if sortOption == .mktCapDesc && platformId == nil {
            cachedToplist[SortOption.mktCapDesc.toplistApiValue] = CachedData(data: toplist, date: Date())
        }
        
        await TrendingRepositoryImp.shared.updateFromToplist(coins: toplist)
        await NewCoinsRepositoryImp.shared.updateFromToplist(coins: toplist)
        await WinnersLosersRepositoryImp.shared.updateFromToplist(coins: toplist)
        await updateFromToplist(coins: toplist)

        return toplist
    }
    
    func getFavorites() async -> [Toplist]? {
        let favoriteCoins: CachedData<[Toplist]>? = await coreDataManager.get(forKey: .favorites)
        let favoriteIds = favoriteCoins?.data.compactMap({ $0.id })

        guard let favoriteIds, !favoriteIds.isEmpty else { return nil }
        
        let toplist = await getMarketToplist(sortOption: .mktCapDesc, priceChange: .sevenDays, platformId: nil)

        var localFavorites = [Toplist]()
        
        favoriteIds.forEach { id in
            if let coin = toplist?.first(where: { $0.id == id }) {
                localFavorites.append(coin)
            }
        }
        
        localFavorites.enumerated().forEach { index, coin in
            if let toplistIndex = cachedFavorites?.data.firstIndex(where: { $0.id == coin.id }) {
                cachedFavorites?.data[toplistIndex] = coin
            } else {
                cachedFavorites?.data.append(coin)
            }
        }

        await coreDataManager.set(cachedFavorites, forKey: .favorites)

        let otherFavourites = favoriteIds.filter({ favourite in !localFavorites.contains(where: { $0.id == favourite }) })
        guard !otherFavourites.isEmpty else {
            return cachedFavorites?.data
        }
        
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        guard let favoriteCoins: [Toplist] = await networkManager.get(
            endpoint: .multipleCoins(
                ids: otherFavourites,
                currency: currency
            )
        ) else {
            return cachedFavorites?.data
        }
        
        favoriteCoins.forEach { coin in
            if let coinIndex = cachedFavorites?.data.firstIndex(where: { $0.id == coin.id }) {
                cachedFavorites?.data[coinIndex] = coin
            } else {
                cachedFavorites?.data.append(coin)
            }
        }
        
        await coreDataManager.set(cachedFavorites, forKey: .favorites)
        
        await TrendingRepositoryImp.shared.updateFromToplist(coins: favoriteCoins)
        await NewCoinsRepositoryImp.shared.updateFromToplist(coins: favoriteCoins)
        await WinnersLosersRepositoryImp.shared.updateFromToplist(coins: favoriteCoins)
        await updateFromToplist(coins: favoriteCoins)
        
        return cachedFavorites?.data
    }
    
    func favouriteButtonPressed(toplist: Toplist) async -> [Toplist] {
        guard var cachedFavorites else {
            return []
        }

        let previousCount = Double(cachedFavorites.data.count)
        let isAdding = !cachedFavorites.data.contains(where: { $0.id == toplist.id })
        
        if let index = cachedFavorites.data.firstIndex(where: { $0.id == toplist.id }) {
            cachedFavorites.data.remove(at: index)
        } else {
            cachedFavorites.data.append(toplist)
        }
        
        self.cachedFavorites = cachedFavorites
        
        await coreDataManager.set(cachedFavorites, forKey: .favorites)
        SettingsManager.shared.set(data: !cachedFavorites.data.isEmpty, key: AppSettingKey.hasHomeFavorites)

#if IS_APP
        if isAdding {
            Task { @MainActor in
                await AchievementManager.shared.checkMetricUnlock(
                    for: .favoritesCount,
                    previousValue: previousCount,
                    newValue: previousCount + 1
                )
            }
        }
#endif
        
        asyncMain {
            NotificationCenter.default.post(Notification(name: .showRatingView, object: nil, userInfo: [:]))
        }
        
        return self.cachedFavorites?.data ?? []
    }
    
    func updateFromToplist(coins: [Toplist]) async {
        guard !coins.isEmpty, var cachedFavorites else { return }
        
        for (index, coin) in coins.enumerated() {
            if let toplistIndex = cachedFavorites.data.firstIndex(where: { $0.id == coin.id }) {
                cachedFavorites.data[toplistIndex] = coins[index]
            }
        }
        
        self.cachedFavorites = cachedFavorites
        await coreDataManager.set(cachedFavorites, forKey: .favorites)
    }
    
    func getCoin(id: String) async -> Toplist? {
        await ensureCacheLoaded()
        
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        guard let coins: [Toplist] = await networkManager.get(
            endpoint: .multipleCoins(
                ids: [id],
                withSparkline: true,
                currency: currency
            )
        ), let coin = coins.first(where: { $0.id == id }) ?? coins.first else {
            return nil
        }
        
        await updateFromToplist(coins: [coin])
        return coin
    }
    
    func refreshForCurrencyChange(sortOption: SortOption, priceChange: PriceChange) async {
        await ensureCacheLoaded()
        
        let storedFavorites: CachedData<[Toplist]>? = await coreDataManager.get(forKey: .favorites)
        let hasFavorites = !(storedFavorites?.data.isEmpty ?? true)
        let hadToplistCache = cachedSmallToplist != nil || !cachedToplist.isEmpty
        
        guard hadToplistCache || hasFavorites else { return }
        
        if hadToplistCache {
            _ = await getSmallToplist()
            
            if !hasFavorites {
                _ = await getMarketToplist(
                    sortOption: sortOption,
                    priceChange: priceChange,
                    platformId: nil
                )
            }
        }
        
        if hasFavorites {
            _ = await getFavorites()
        }
    }
}
