//
//  ExchangesRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-17.
//

import Foundation
import Combine

protocol ExchangesRepository: Actor {
    var cachedExchanges: CachedData<[ExchangeModel]>? { get }
    
    func ensureCacheLoaded() async
    func getExchanges() async -> [ExchangeModel]?
}

final actor ExchangesRepositoryImp: ExchangesRepository {
    static let shared = ExchangesRepositoryImp()
    
    private let networkManager: NetworkManager
    
    private(set) var cachedExchanges: CachedData<[ExchangeModel]>?
    
    init(networkManager: NetworkManager = NetworkManagerImp.shared) {
        self.networkManager = networkManager
        self.cachedExchanges = nil
    }
    
    private var hasLoadedFromStorage = false
    
    func ensureCacheLoaded() async {
        guard !hasLoadedFromStorage else { return }
        hasLoadedFromStorage = true
        if let exchanges: [ExchangeModel] = await networkManager.getCached(endpoint: .exchanges) {
            cachedExchanges = CachedData(data: exchanges, date: Date())
        }
    }

    func getExchanges() async -> [ExchangeModel]? {
        await ensureCacheLoaded()
        let exchanges: [ExchangeModel]? = await networkManager.get(endpoint: .exchanges)
        
        if let exchanges {
            cachedExchanges = CachedData(data: exchanges, date: Date())
        }
        
        return exchanges
    }
}
