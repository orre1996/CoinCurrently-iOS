//
//  GasFeesRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-03-18.
//

import Foundation
import Combine

protocol GasFeesRepository: Actor {
    var cachedGasFees: CachedData<GasFees>? { get }
    var cachedGasFeePrices: CachedData<GasFees>? { get }
    
    func ensureCacheLoaded() async
    func getGasFees() async -> GasFees?
    func getGasFeePrices() async -> GasFees?
}

final actor GasFeesRepositoryImp: GasFeesRepository {
    static let shared = GasFeesRepositoryImp()

    private(set) var cachedGasFees: CachedData<GasFees>?
    private(set) var cachedGasFeePrices: CachedData<GasFees>?

    private let networkManager: NetworkManager
    private let firebaseManager: FirebaseManager
    private var hasLoadedFromStorage = false
    
    init(
        networkManager: NetworkManager = NetworkManagerImp.shared,
        firebaseManager: FirebaseManager = FirebaseManagerImp.shared
    ) {
        self.networkManager = networkManager
        self.firebaseManager = firebaseManager
        self.cachedGasFees = nil
        self.cachedGasFeePrices = nil
    }
    
    func ensureCacheLoaded() async {
        guard !hasLoadedFromStorage else { return }
        hasLoadedFromStorage = true
        if let gasFees: GasFees = await networkManager.getCached(endpoint: .gasFees(includeHistory: false)) {
            cachedGasFees = CachedData(data: gasFees, date: Date())
        }
        if let gasFeePrices: GasFees = await networkManager.getCached(endpoint: .gasFees(includeHistory: true)) {
            cachedGasFeePrices = CachedData(data: gasFeePrices, date: Date())
        }
    }
    
    func getGasFees() async -> GasFees? {
        await ensureCacheLoaded()
        let gasFeesModel: GasFees? = await networkManager.get(endpoint: .gasFees(includeHistory: false))

        if let gasFeesModel {
            cachedGasFees = CachedData(data: gasFeesModel, date: Date())
        }

        return gasFeesModel
    }
    
    func getGasFeePrices() async -> GasFees? {
        await ensureCacheLoaded()
        let gasFeesPrices: GasFees? = await networkManager.get(endpoint: .gasFees(includeHistory: true))
        
        if let gasFeesPrices {
            cachedGasFeePrices = CachedData(data: gasFeesPrices, date: Date())
        }
        
        return gasFeesPrices
    }
}


