//
//  ExploreViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-08-27.
//

import Foundation

@MainActor
protocol ExploreViewModel {
    var category: CryptoCategory? { get }
    var coins: [Toplist] { get }
    var currentIndex: Int { get }
    var isLoading: Bool { get }
    var hasLoaded: Bool { get }
    var startedWithoutCategory: Bool { get }
    var currentCoin: Toplist? { get }
    var nextCoin: Toplist? { get }
    var isExhausted: Bool { get }
    
    func selectCategory(_ category: CryptoCategory) async
    func loadCoins() async
    func skip()
    func restart()
    func goBackToCategoryPicker()
}

@MainActor @Observable
final class ExploreViewModelImp: ExploreViewModel {
    private(set) var category: CryptoCategory?
    private(set) var coins = [Toplist]()
    private(set) var currentIndex = 0
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    let startedWithoutCategory: Bool
    
    private let toplistRepository: ToplistRepository
    private let networkManager: NetworkManager
    
    init(
        category: CryptoCategory? = nil,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        networkManager: NetworkManager = NetworkManagerImp.shared
    ) {
        self.category = category
        self.startedWithoutCategory = category == nil
        self.toplistRepository = toplistRepository
        self.networkManager = networkManager
    }
    
    var currentCoin: Toplist? {
        guard currentIndex < coins.count else { return nil }
        return coins[currentIndex]
    }
    
    var nextCoin: Toplist? {
        guard currentIndex + 1 < coins.count else { return nil }
        return coins[currentIndex + 1]
    }
    
    var isExhausted: Bool {
        hasLoaded && !isLoading && (coins.isEmpty || currentIndex >= coins.count)
    }
    
    func selectCategory(_ category: CryptoCategory) async {
        self.category = category
        currentIndex = 0
        coins.removeAll()
        hasLoaded = false
        await loadCoins()
    }
    
    func loadCoins() async {
        guard let categoryId = category?.id else { return }
        
        isLoading = true
        
        await toplistRepository.ensureCacheLoaded()
        
        if let toplist = await toplistRepository.getMarketToplist(
            sortOption: .mktCapDesc,
            priceChange: .sevenDays,
            platformId: categoryId
        ) {
            coins = toplist.filter { $0.symbol != "Secret message" && $0.id != nil }
        }
        
        await enrichCoinsWithSparklines()
        
        isLoading = false
        hasLoaded = true
    }
    
    private func enrichCoinsWithSparklines() async {
        let ids = coins.compactMap(\.id)
        guard !ids.isEmpty else { return }
        
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        var enrichedById: [String: Toplist] = [:]
        
        for chunk in ids.chunked(into: 100) {
            guard let enriched: [Toplist] = await networkManager.get(
                endpoint: .multipleCoins(
                    ids: chunk,
                    withSparkline: true,
                    currency: currency
                )
            ) else {
                continue
            }
            
            for coin in enriched {
                if let id = coin.id {
                    enrichedById[id] = coin
                }
            }
        }
        
        coins = coins.map { coin in
            guard let id = coin.id, let enriched = enrichedById[id] else { return coin }
            return enriched
        }
    }
    
    func skip() {
        guard currentIndex < coins.count else { return }
        currentIndex += 1
    }
    
    func restart() {
        currentIndex = 0
    }
    
    func goBackToCategoryPicker() {
        category = nil
        coins.removeAll()
        currentIndex = 0
        hasLoaded = false
    }
}
