//
//  NewCoinsRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-09-14.
//

import Foundation
import Combine

protocol NewCoinsRepository: Actor {
    var cachedNewCoins: CachedData<[Toplist]>? { get }
    
    func ensureCacheLoaded() async
    func getNewCoins() async -> [Toplist]?
    func getActualCoins(ids: [String]) async -> [Toplist]?
    func updateFromToplist(coins: [Toplist])
}

final actor NewCoinsRepositoryImp: NewCoinsRepository {
    static let shared = NewCoinsRepositoryImp()

    private(set) var cachedNewCoins: CachedData<[Toplist]>?

    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager = NetworkManagerImp.shared) {
        self.networkManager = networkManager
        self.cachedNewCoins = nil
    }
    
    private var hasLoadedFromStorage = false
    
    func ensureCacheLoaded() async {
        guard !hasLoadedFromStorage else { return }
        hasLoadedFromStorage = true
        if let coins: [CoinsListModel] = await networkManager.getCached(endpoint: .newCoins) {
            let ids = coins.sorted(by: { ($0.activated_at ?? 0) > ($1.activated_at ?? 0) }).compactMap { $0.id }.prefix(25)
            if !ids.isEmpty {
                let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
                if let toplist: [Toplist] = await networkManager.getCached(
                    endpoint: .multipleCoins(ids: Array(ids), currency: currency)
                ) {
                    cachedNewCoins = CachedData(data: toplist, date: Date())
                }
            }
        }
    }
    
    func getNewCoins() async -> [Toplist]? {
        await ensureCacheLoaded()
        guard let coins: [CoinsListModel] = await networkManager.get(endpoint: .newCoins) else { return nil }

        let ids = coins.sorted(by: { ($0.activated_at ?? 0) > ($1.activated_at ?? 0) }).compactMap { $0.id }.prefix(25)
    
        return await getActualCoins(ids: Array(ids))
    }

    func getActualCoins(ids: [String]) async -> [Toplist]? {
        await ensureCacheLoaded()
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        guard
            !ids.isEmpty,
            let coins: [Toplist] = await networkManager.get(
                endpoint: .multipleCoins(ids: ids, currency: currency)
            ) else {
            return nil
        }

        cachedNewCoins = CachedData(data: coins, date: Date())
        
        await ToplistRepositoryImp.shared.updateFromToplist(coins: coins)
        await TrendingRepositoryImp.shared.updateFromToplist(coins: coins)
        await WinnersLosersRepositoryImp.shared.updateFromToplist(coins: coins)

        return coins
    }
    
    func updateFromToplist(coins: [Toplist]) {
        guard let newCoins = cachedNewCoins?.data, !coins.isEmpty else { return }

        newCoins.enumerated().forEach { index, newCoin in
            if let coinIndex = coins.firstIndex(where: { $0.id == newCoin.id }) {
                cachedNewCoins?.data[index] = coins[coinIndex]
            }
        }
    }
}
