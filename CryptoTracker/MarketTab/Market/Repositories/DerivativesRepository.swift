//
//  DerivativesRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-17.
//

import Foundation
import Combine

protocol DerivativesRepository: Actor {
    var cachedDerivatives: [String: CachedData<[Derivative]>] { get }
    
    func ensureCacheLoaded() async
    func getDerivatives(sortOption: SortOption) async -> [Derivative]?
}

final actor DerivativesRepositoryImp: DerivativesRepository {
    static let shared = DerivativesRepositoryImp()
    
    private let networkManager: NetworkManager

    var cachedDerivatives: [String: CachedData<[Derivative]>]

    init(networkManager: NetworkManager = NetworkManagerImp.shared) {
        self.networkManager = networkManager
        self.cachedDerivatives = [:]
    }
    
    private var hasLoadedFromStorage = false
    
    func ensureCacheLoaded() async {
        guard !hasLoadedFromStorage else { return }
        hasLoadedFromStorage = true
        for sortOption in SortOption.derivativesOptions {
            if let derivatives: [Derivative] = await networkManager.getCached(endpoint: .allDerivatives(sortOption: sortOption)) {
                cachedDerivatives[sortOption.derivativesApiValue] = CachedData(data: derivatives, date: Date())
            }
        }
    }

    func getDerivatives(sortOption: SortOption) async -> [Derivative]? {
        await ensureCacheLoaded()
        let derivatives: [Derivative]? = await networkManager.get(endpoint: .allDerivatives(sortOption: sortOption))

        if let derivatives {
            cachedDerivatives[sortOption.derivativesApiValue] = CachedData(data: derivatives, date: Date())
        }
        
        return derivatives
    }
}
