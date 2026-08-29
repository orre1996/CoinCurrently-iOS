//
//  DerivativeDetailsRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-20.
//

import Foundation

protocol DerivativeDetailsRepository: Actor {
    var cachedDerivatives: [String: CachedData<Derivative>] { get }
    
    func ensureCacheLoaded() async
    func getDerivativeDetail(id: String?) async -> Derivative?
    func getExchangeImage(imageUrl: String?) async -> Data?
}

final actor DerivativeDetailsRepositoryImp: DerivativeDetailsRepository {
    static let shared = DerivativeDetailsRepositoryImp()
    
    private let networkManager: NetworkManager

    private(set) var cachedDerivatives: [String: CachedData<Derivative>] = [:]

    init(networkManager: NetworkManager = NetworkManagerImp.shared) {
        self.networkManager = networkManager
    }
    
    func ensureCacheLoaded() async {}
    
    func getDerivativeDetail(id: String?) async -> Derivative? {
        guard let id else { return nil }

        let derivative: Derivative? = await networkManager.get(endpoint: .exchangeDerivatives(exchange: id))

        if let derivative {
            cachedDerivatives[id] = CachedData(data: derivative.copy(withId: id), date: Date())
        }

        return derivative?.copy(withId: id)
    }
    
    func getExchangeImage(imageUrl: String?) async -> Data? {
        guard let imageUrl else { return nil }

        return await networkManager.get(endpoint: .image(url: imageUrl))
    }
}
