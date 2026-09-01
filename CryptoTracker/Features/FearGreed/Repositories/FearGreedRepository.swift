//
//  FearGreedRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-16.
//

import Foundation

protocol FearGreedRepository: Actor {
    var cachedFearGreed: CachedData<FearGreed>? { get }
    
    func ensureCacheLoaded() async
    func getFearGreed() async -> FearGreed?
}

final actor FearGreedRepositoryImp: FearGreedRepository {
    static let shared = FearGreedRepositoryImp()
    
    private let networkManager: NetworkManager

    var cachedFearGreed: CachedData<FearGreed>?

    init(networkManager: NetworkManager = NetworkManagerImp.shared) {
        self.networkManager = networkManager
        self.cachedFearGreed = nil
    }

    func ensureCacheLoaded() async {
        if let fearGreed: FearGreed = await networkManager.getCached(endpoint: .fearAndGreed) {
            cachedFearGreed = CachedData(data: fearGreed, date: Date())
        }
    }

    func getFearGreed() async -> FearGreed? {
        await ensureCacheLoaded()
        if let fearGreed: FearGreed = await networkManager.get(endpoint: .fearAndGreed) {
            cachedFearGreed = CachedData(data: fearGreed, date: Date())
            return fearGreed
        }

        return cachedFearGreed?.data
    }
}
