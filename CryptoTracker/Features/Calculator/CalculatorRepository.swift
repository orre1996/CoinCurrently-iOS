//
//  CalculatorRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-14.
//

import Foundation

protocol CalculatorRepository: Actor {
    var cachedPrices: CachedData<[Cryptocurrency]>? { get }
    
    func ensureCacheLoaded() async
    func getCalculatorPrices(ids: [String]) async -> [Cryptocurrency]?
}

final actor CalculatorRepositoryImp: CalculatorRepository {
    static let shared = CalculatorRepositoryImp()

    private let networkManager: NetworkManager
    private let toplistRepository: ToplistRepository

    private(set) var cachedPrices: CachedData<[Cryptocurrency]>?
    
    init(
        networkManager: NetworkManager = NetworkManagerImp.shared,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared
    ) {
        self.networkManager = networkManager
        self.toplistRepository = toplistRepository
    }
    
    func ensureCacheLoaded() async {
        guard cachedPrices == nil else { return }
        await toplistRepository.ensureCacheLoaded()
        let sortedToplist: [Toplist]? = await toplistRepository.cachedSmallToplist?.data.sorted(by: { $0.market_cap_rank ?? 9999 < $1.market_cap_rank ?? 9999 })
        guard let ids: [String] = sortedToplist?.compactMap(\.id), !ids.isEmpty else {
            return
        }
        if let allPrices: CurrencyPricesAllCurrencies = await networkManager.getCached(endpoint: .coinsWithCurrencies(ids: ids)) {
            cachedPrices = CachedData(data: allPrices.cryptocurrencies, date: Date())
        }
    }
    
    func getCalculatorPrices(ids: [String]) async -> [Cryptocurrency]? {
        await ensureCacheLoaded()
        guard !ids.isEmpty, let allPrices: CurrencyPricesAllCurrencies = await networkManager.get(endpoint: .coinsWithCurrencies(ids: ids)) else {
            return nil
        }

        cachedPrices = CachedData(data: allPrices.cryptocurrencies, date: Date())
        return allPrices.cryptocurrencies
    }
}
