//
//  WinnersLosersRepostiroy.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-12-26.
//

import Foundation
import Combine

protocol WinnersLosersRepository: Actor {
    var cachedWinnersLosers: [String: CachedData<WinnersLosers>] { get }
    var cachedWinnersCoins: [String: CachedData<[Toplist]>] { get }
    var cachedLosersCoins: [String: CachedData<[Toplist]>] { get }
    
    func ensureCacheLoaded() async
    func getWinners(priceChange: PriceChange) async -> [Toplist]?
    func getLosers(priceChange: PriceChange) async -> [Toplist]?
    func getWinnersLosersList(priceChange: PriceChange) async -> WinnersLosers?
    func updateFromToplist(coins: [Toplist])
}

final actor WinnersLosersRepositoryImp: WinnersLosersRepository {
    static let shared = WinnersLosersRepositoryImp()
    
    private let networkManager: NetworkManager

    var cachedWinnersLosers: [String: CachedData<WinnersLosers>]
    var cachedWinnersCoins: [String: CachedData<[Toplist]>]
    var cachedLosersCoins: [String: CachedData<[Toplist]>]
    
    init(
        networkManager: NetworkManager = NetworkManagerImp.shared
    ) {
        self.networkManager = networkManager
        self.cachedWinnersLosers = [:]
        self.cachedWinnersCoins = [:]
        self.cachedLosersCoins = [:]
    }
    
    private var hasLoadedFromStorage = false
    
    func ensureCacheLoaded() async {
        guard !hasLoadedFromStorage else { return }
        hasLoadedFromStorage = true
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        
        for priceChange in PriceChange.allCases {
            if let winnersLosers: WinnersLosers = await networkManager.getCached(
                endpoint: .winnersLosers(priceChange: priceChange, currency: currency)
            ) {
                cachedWinnersLosers[priceChange.rawValue] = CachedData(data: winnersLosers, date: Date())
                let winnerIds = winnersLosers.top_gainers.map { $0.id }
                let loserIds = winnersLosers.top_losers.map { $0.id }
                if !winnerIds.isEmpty, let coins: [Toplist] = await networkManager.getCached(
                    endpoint: .multipleCoins(ids: winnerIds, currency: currency)
                ) {
                    cachedWinnersCoins[priceChange.rawValue] = CachedData(data: coins.getSortedToplist(sortOption: .priceChangeDesc, priceChange: priceChange), date: Date())
                }
                if !loserIds.isEmpty, let coins: [Toplist] = await networkManager.getCached(
                    endpoint: .multipleCoins(ids: loserIds, currency: currency)
                ) {
                    cachedLosersCoins[priceChange.rawValue] = CachedData(data: coins.getSortedToplist(sortOption: .priceChangeAsc, priceChange: priceChange), date: Date())
                }
            }
        }
    }
    
    func getWinners(priceChange: PriceChange) async -> [Toplist]? {
        await ensureCacheLoaded()
        guard let winnersLosers: WinnersLosers = await getWinnersLosersList(priceChange: priceChange) else {
            return nil
        }
        
        let coinIds = winnersLosers.top_gainers.map { $0.id }
        guard !coinIds.isEmpty else { return nil }
        
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        guard let winnerCoins: [Toplist] = await networkManager.get(
            endpoint: .multipleCoins(ids: coinIds, currency: currency)
        ) else {
            return nil
        }
        
        let sortedWinners = winnerCoins.getSortedToplist(sortOption: .priceChangeDesc, priceChange: priceChange)
        
        cachedWinnersCoins[priceChange.rawValue] = CachedData(data: sortedWinners, date: Date())
        
        await ToplistRepositoryImp.shared.updateFromToplist(coins: sortedWinners)
        await TrendingRepositoryImp.shared.updateFromToplist(coins: sortedWinners)
        await NewCoinsRepositoryImp.shared.updateFromToplist(coins: sortedWinners)
        
        return sortedWinners
    }
    
    func getLosers(priceChange: PriceChange) async -> [Toplist]? {
        await ensureCacheLoaded()
        guard let winnersLosers: WinnersLosers = await getWinnersLosersList(priceChange: priceChange) else {
            return nil
        }
        
        let coinIds = winnersLosers.top_losers.map { $0.id }
        guard !coinIds.isEmpty else { return nil }
        
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        guard let loserCoins: [Toplist] = await networkManager.get(
            endpoint: .multipleCoins(ids: coinIds, currency: currency)
        ) else {
            return nil
        }
        
        let sortedLosers = loserCoins.getSortedToplist(sortOption: .priceChangeAsc, priceChange: priceChange)
        
        cachedLosersCoins[priceChange.rawValue] = CachedData(data: sortedLosers, date: Date())
        
        await ToplistRepositoryImp.shared.updateFromToplist(coins: sortedLosers)
        await TrendingRepositoryImp.shared.updateFromToplist(coins: sortedLosers)
        await NewCoinsRepositoryImp.shared.updateFromToplist(coins: sortedLosers)
        
        return sortedLosers
    }
    
    func getWinnersLosersList(priceChange: PriceChange) async -> WinnersLosers? {
        await ensureCacheLoaded()
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        let winnersLosers: WinnersLosers? = await networkManager.get(
            endpoint: .winnersLosers(priceChange: priceChange, currency: currency)
        )
        
        if let winnersLosers {
            cachedWinnersLosers[priceChange.rawValue] = CachedData(data: winnersLosers, date: Date())
        }
        
        return winnersLosers
    }

    func updateFromToplist(coins: [Toplist]) {
        guard !coins.isEmpty else { return }

        cachedWinnersCoins.forEach { key, value in
            var winners = value.data
            coins.enumerated().forEach { index, trending in
                if let coinIndex = winners.firstIndex(where: { $0.id == trending.id && $0.id != nil }) {
                    winners[coinIndex] = coins[index]
                }
            }
            cachedWinnersCoins[key]?.data = winners
        }
        
        cachedLosersCoins.forEach { key, value in
            var losers = value.data
            coins.enumerated().forEach { index, trending in
                if let coinIndex = losers.firstIndex(where: { $0.id == trending.id && $0.id != nil }) {
                    losers[coinIndex] = coins[index]
                }
            }
            cachedLosersCoins[key]?.data = losers
        }
    }
}
