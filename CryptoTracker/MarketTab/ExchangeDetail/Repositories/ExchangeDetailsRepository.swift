//
//  ExchangeDetailsRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-22.
//

import Foundation

protocol ExchangeDetailsRepository: Actor {
    var cachedExchangeDetail: [String: CachedData<Exchange>] { get }
    var cachedExchangePrices: [String: CachedData<[ExchangePriceModel]>] { get }
    
    func ensureCacheLoaded() async
    func loadCachedDataForExchange(id: String, days: String) async
    func getExchangeDetails(id: String?) async -> Exchange?
    func getExchangePrices(id: String?, days: String) async -> [ExchangePriceModel]?
}

final actor ExchangeDetailsRepositoryImp: ExchangeDetailsRepository {
    static let shared = ExchangeDetailsRepositoryImp()
    
    private let networkManager: NetworkManager
    
    private(set) var cachedExchangeDetail: [String: CachedData<Exchange>]
    private(set) var cachedExchangePrices: [String: CachedData<[ExchangePriceModel]>]
    
    init(networkManager: NetworkManager = NetworkManagerImp.shared) {
        self.networkManager = networkManager
        self.cachedExchangeDetail = [:]
        self.cachedExchangePrices = [:]
    }
    
    private var hasLoadedFromStorage = false
    
    func ensureCacheLoaded() async {
        guard !hasLoadedFromStorage else { return }
        hasLoadedFromStorage = true
    }

    func loadCachedDataForExchange(id: String, days: String) async {
        await ensureCacheLoaded()

        if let exchangeDetail: Exchange = await networkManager.getCached(endpoint: .exchange(id: id)) {
            cachedExchangeDetail[id] = CachedData(data: exchangeDetail.copy(withId: id), date: Date())
        }

        if let exchangePrices: [ExchangePriceModel] = await networkManager.getCached(endpoint: .exchangeVolume(id: id, days: days)) {
            cachedExchangePrices["\(id)-\(days)"] = CachedData(data: exchangePrices, date: Date())
        }
    }

    func getExchangeDetails(id: String?) async -> Exchange? {
        await ensureCacheLoaded()
        guard let id else { return nil }
        
        let exchangeDetail: Exchange? = await networkManager.get(endpoint: .exchange(id: id))
        
        if let exchangeDetail {
            cachedExchangeDetail[id] = CachedData(data: exchangeDetail.copy(withId: id), date: Date())
        }
        
        return exchangeDetail?.copy(withId: id)
    }

    func getExchangePrices(id: String?, days: String) async -> [ExchangePriceModel]? {
        await ensureCacheLoaded()
        guard let id else { return nil }
        
        let exchangePrices: [ExchangePriceModel]? = await networkManager.get(endpoint: .exchangeVolume(id: id, days: days))
        
        if let exchangePrices {
            cachedExchangePrices["\(id)-\(days)"] = CachedData(data: exchangePrices, date: Date())
        }
        
        return exchangePrices
    }
}
