//
//  HomeViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-09-14.
//

import Foundation
import SwiftUI
import Combine

@MainActor
protocol HomeViewModel {
    func setStartData() async
    func downloadData() async
    func getGlobalMarket() async
    func getGasFees() async
    func getFearGreed() async
    func favouriteButtonPressed(toplistItem: Toplist?) async
    
    func getList(filter: CarouselFilter) -> [Toplist]?
    func toplistSeeAll() async
    
    var globalMarket: GlobalMarketModel? { get }
    var trendingCoins: [Toplist]? { get }
    var newCoins: [Toplist]? { get }
    var fearGreed: FearGreed? { get }
    var gasFees: GasFees? { get }
    
    var selectedFilter: CarouselFilter? { get set }
    var toplist: [Toplist]? { get }
    var favoritesList: [Toplist] { get }
    var winnersList: [Toplist]? { get }
    var losersList: [Toplist]? { get }
}

@Observable @MainActor
class HomeViewModelImp: HomeViewModel {
    private var homeListPreviewCount: Int {
        isPad ? 20 : 10
    }
    private var cancellable: Set<AnyCancellable> = []
    
    private let toplistRepository: ToplistRepository
    private let cryptoDetailRepository: CryptoDetailRepository
    private let winnersLosersRepository: WinnersLosersRepository
    private let globalMarketRepository: GlobalMarketRepository
    private let fearGreedRepository: FearGreedRepository
    private let gasFeesRepository: GasFeesRepository
    private let trendingRepository: TrendingRepository
    private let newCoinsRepository: NewCoinsRepository
    private let cachedStorageManager: CachedStorageManager
    private let settingsManager: SettingsManager
    private let analyticsManager: AnalyticsManager
    
    var selectedFilter: CarouselFilter?
    var toplist: [Toplist]?
    var favoritesList = [Toplist]()
    var winnersList: [Toplist]?
    var losersList: [Toplist]?
    var globalMarket: GlobalMarketModel?
    var trendingCoins: [Toplist]?
    var newCoins: [Toplist]?
    var fearGreed: FearGreed?
    var gasFees: GasFees?
    
    private(set) var scrollToTopActive = false
    
    init(
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared,
        winnersLosersRepository: WinnersLosersRepository = WinnersLosersRepositoryImp.shared,
        globalMarketRepository: GlobalMarketRepository = GlobalMarketRepositoryImp.shared,
        trendingRepository: TrendingRepository = TrendingRepositoryImp.shared,
        newCoinsRepository: NewCoinsRepository = NewCoinsRepositoryImp.shared,
        fearGreedRepository: FearGreedRepository = FearGreedRepositoryImp.shared,
        gasFeesRepository: GasFeesRepository = GasFeesRepositoryImp.shared,
        cachedStorageManager: CachedStorageManager = CachedStorageManagerImp.shared,
        settingsManager: SettingsManager = SettingsManager.shared,
        analyticsManager: AnalyticsManager = AnalyticsManager.shared
    ) {
        self.toplistRepository = toplistRepository
        self.cryptoDetailRepository = cryptoDetailRepository
        self.winnersLosersRepository = winnersLosersRepository
        self.globalMarketRepository = globalMarketRepository
        self.trendingRepository = trendingRepository
        self.newCoinsRepository = newCoinsRepository
        self.fearGreedRepository = fearGreedRepository
        self.gasFeesRepository = gasFeesRepository
        self.cachedStorageManager = cachedStorageManager
        self.settingsManager = settingsManager
        self.analyticsManager = analyticsManager
        let hasFavorites: Bool = settingsManager.get(key: AppSettingKey.hasHomeFavorites) ?? false
        selectedFilter = CarouselFilter.defaultHomeFilter(hasFavorites: hasFavorites)
    }
    
    func setStartData() async {
        async let favorites: Void = loadFavorites()

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.publishCachedToplist() }
            group.addTask { await self.publishCachedWinnersAndLosers() }
            group.addTask { await self.publishCachedTrending() }
            group.addTask { await self.publishCachedNewCoins() }
            group.addTask { await self.publishCachedGlobalMarket() }
            group.addTask { await self.publishCachedFearGreed() }
            group.addTask { await self.publishCachedGasFees() }
            group.addTask { await self.cryptoDetailRepository.ensureCacheLoaded() }
        }

        await favorites
    }
    
    func getList(filter: CarouselFilter) -> [Toplist]? {
        switch filter {
        case .topCoins:
            return toplist
        case .favorites:
            return favoritesList
        case .trending:
            return trendingCoins
        case .timeframeWinners:
            return winnersList
        case .timeframeLosers:
            return losersList
        case .newlyListed:
            return newCoins
        default:
            return []
        }
    }
    
    func downloadData() async {
        switch selectedFilter ?? .topCoins {
        case .topCoins:
            await getToplist()
        case .favorites:
            await getFavorites()
        case .trending:
            await getTrendingCoins()
        case .timeframeWinners:
            await getWinners()
        case .timeframeLosers:
            await getLosers()
        case .newlyListed:
            await getNewCoins()
        default:
            return
        }
    }

    func toplistSeeAll() async {
        let newSort: SortOption?

        switch selectedFilter {
        case .topCoins:
            newSort = .mktCapDesc

        case .timeframeWinners:
            newSort = .priceChangeDesc

        case .timeframeLosers:
            newSort = .priceChangeAsc

        default:
            return
        }

        guard let newSort else {
            return
        }
        
        await cachedStorageManager.save(type: AppSettingKey.toplistSortOption.rawValue, data: newSort)
        NotificationCenter.default.post(
            name: .changeMarketPage,
            object: nil,
            userInfo: ["page": 0, "sortOption": newSort.rawValue]
        )
    }

    // MARK: - Toplist

    func getToplist() async {
        if let toplist = await toplistRepository.getSmallToplist() {
            self.toplist = Array(toplist.prefix(homeListPreviewCount))
            await setStartData()
        }
    }
    
    func getFavorites() async {
        if let favorites = await toplistRepository.getFavorites() {
            self.favoritesList = favorites.sorted(by: { $0.market_cap_rank ?? 9999 < $1.market_cap_rank ?? 9999 })
            await setStartData()
        }
    }

    func getWinners() async {
        if let winners = await winnersLosersRepository.getWinners(priceChange: .sevenDays) {
            self.winnersList = Array(winners.sorted(by: { ($0.price_change_percentage_7d_in_currency ?? 0) > ($1.price_change_percentage_7d_in_currency ?? 0) }).prefix(homeListPreviewCount))
            await setStartData()
        }
    }
    
    func getLosers() async {
        if let losers = await winnersLosersRepository.getLosers(priceChange: .sevenDays) {
            self.losersList = Array(losers.sorted(by: { ($0.price_change_percentage_7d_in_currency ?? 0) < ($1.price_change_percentage_7d_in_currency ?? 0) }).prefix(homeListPreviewCount))
            await setStartData()
        }
    }
    
    private func loadFavorites() async {
        await toplistRepository.ensureFavoritesLoaded()
        if let favorites = await toplistRepository.cachedFavorites?.data {
            favoritesList = favorites.sorted(by: { $0.market_cap_rank ?? 9999 < $1.market_cap_rank ?? 9999 })
        }
        settingsManager.set(data: !favoritesList.isEmpty, key: AppSettingKey.hasHomeFavorites)
    }

    private func publishCachedToplist() async {
        await toplistRepository.ensureCacheLoaded()

        if let toplist = await toplistRepository.cachedSmallToplist?.data, !toplist.isEmpty {
            self.toplist = Array(toplist.prefix(homeListPreviewCount))
        } else if let toplist = await toplistRepository.cachedToplist[SortOption.mktCapDesc.toplistApiValue]?.data, !toplist.isEmpty {
            self.toplist = Array(toplist.prefix(homeListPreviewCount))
        }

        if let favorites = await toplistRepository.cachedFavorites?.data {
            favoritesList = favorites.sorted(by: { $0.market_cap_rank ?? 9999 < $1.market_cap_rank ?? 9999 })
        }
    }

    private func publishCachedWinnersAndLosers() async {
        await winnersLosersRepository.ensureCacheLoaded()
        let timeFrame = "7"

        if let winners = await winnersLosersRepository.cachedWinnersCoins[timeFrame]?.data, !winners.isEmpty {
            winnersList = Array(winners.sorted(by: { ($0.price_change_percentage_7d_in_currency ?? 0) > ($1.price_change_percentage_7d_in_currency ?? 0) }).prefix(homeListPreviewCount))
        }

        if let losers = await winnersLosersRepository.cachedLosersCoins[timeFrame]?.data, !losers.isEmpty {
            losersList = Array(losers.sorted(by: { ($0.price_change_percentage_7d_in_currency ?? 0) > ($1.price_change_percentage_7d_in_currency ?? 0) }).prefix(homeListPreviewCount))
        }
    }

    private func publishCachedTrending() async {
        await trendingRepository.ensureCacheLoaded()
        if let trendingCoins = await trendingRepository.cachedTrendingCoins?.data, !trendingCoins.isEmpty {
            let orderedTrendingCoins = await orderedTrendingCoins(trendingCoins)
            self.trendingCoins = Array(orderedTrendingCoins.prefix(homeListPreviewCount))
        }
    }

    private func publishCachedNewCoins() async {
        await newCoinsRepository.ensureCacheLoaded()
        if let newCoins = await newCoinsRepository.cachedNewCoins?.data, !newCoins.isEmpty {
            self.newCoins = Array(newCoins.prefix(homeListPreviewCount))
        }
    }

    private func publishCachedGlobalMarket() async {
        await globalMarketRepository.ensureCacheLoaded()
        if let globalMarket = await globalMarketRepository.cachedGlobalMarket?.data {
            self.globalMarket = globalMarket
        }
    }

    private func publishCachedFearGreed() async {
        await fearGreedRepository.ensureCacheLoaded()
        if let fearGreed = await fearGreedRepository.cachedFearGreed?.data {
            self.fearGreed = fearGreed
        }
    }

    private func publishCachedGasFees() async {
        await gasFeesRepository.ensureCacheLoaded()
        if let data = await gasFeesRepository.cachedGasFees?.data {
            self.gasFees = data
        }
    }

    func favouriteButtonPressed(toplistItem: Toplist?) async {
        guard let toplistItem else { return }

        if favoritesList.contains(where: { $0.id == toplistItem.id }) {
            analyticsManager.log(FavoriteRemoved(coinName: toplistItem.name ?? "", fromScreen: .home, carouselFilter: selectedFilter))
        } else {
            analyticsManager.log(FavoriteAdded(coinName: toplistItem.name ?? "", fromScreen: .home, carouselFilter: selectedFilter))
        }
           
        favoritesList = await toplistRepository.favouriteButtonPressed(toplist: toplistItem).sorted(by: { $0.market_cap_rank ?? 9999 < $1.market_cap_rank ?? 9999 })
        settingsManager.set(data: !favoritesList.isEmpty, key: AppSettingKey.hasHomeFavorites)
    }
    
    // MARK: - Trending

    func getTrendingCoins() async {
        if let trendingCoins = await trendingRepository.getTrendingCoins() {
            let orderedTrendingCoins = await orderedTrendingCoins(trendingCoins)
            self.trendingCoins = Array(orderedTrendingCoins.prefix(homeListPreviewCount))
            await setStartData()
        }
    }
    
    // MARK: - New coins

    func getNewCoins() async {
        if let newCoins = await newCoinsRepository.getNewCoins() {
            self.newCoins = Array(newCoins.prefix(homeListPreviewCount))
            await setStartData()
        }
    }
    
    // MARK: - Global market

    func getGlobalMarket() async {
        if let globalMarket = await globalMarketRepository.getGlobalMarket() {
            self.globalMarket = globalMarket
        }
    }

    // MARK: - Fear and Greed
    
    func getFearGreed() async {
        if let fearGreed = await fearGreedRepository.getFearGreed() {
            self.fearGreed = fearGreed
        }
    }
    
    // MARK: - Gas fees

    func getGasFees() async {
        if let gasFees = await gasFeesRepository.getGasFees() {
            self.gasFees = gasFees
        }
    }

    // MARK: - Private functions

    private func orderedTrendingCoins(_ coins: [Toplist]) async -> [Toplist] {
        guard
            let trendingIds = await trendingRepository.cachedTrending?.data.coins?.compactMap({ $0.item?.id }),
            !trendingIds.isEmpty
        else {
            return coins
        }

        return trendingIds.compactMap { id in
            coins.first(where: { $0.id == id })
        }
    }
}

