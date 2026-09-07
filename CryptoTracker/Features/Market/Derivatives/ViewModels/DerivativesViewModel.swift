//
//  DerivativesViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-17.
//

import Foundation

@MainActor
protocol DerivativesViewModel {
    var derivatives: [Derivative] { get }
    var bitcoin: CurrencyDataModel? { get }
    var selectedSortOption: SortOption { get set }

    func setStartData() async
    func setNewSortOption(newSortOption: SortOption) async
    func getDerivatives(newSortOption: SortOption) async
    func getBitcoin() async
}

@MainActor @Observable
final class DerivativesViewModelImp: DerivativesViewModel, ObservableObject {
    private(set) var derivatives = [Derivative]()
    private(set) var bitcoin: CurrencyDataModel?
    
    var selectedSortOption: SortOption = .mktCapDesc
    
    private let derivativesRepository: DerivativesRepository
    private let cryptoDetailRepository: CryptoDetailRepository
    private let storageManager: CachedStorageManager
    
    init(
        derivativesRepository: DerivativesRepository = DerivativesRepositoryImp.shared,
        cryptoDetailRepository: CryptoDetailRepositoryImp = CryptoDetailRepositoryImp.shared,
        storageManager: CachedStorageManager = CachedStorageManagerImp.shared
    ) {
        self.derivativesRepository = derivativesRepository
        self.cryptoDetailRepository = cryptoDetailRepository
        self.storageManager = storageManager
        
        self.selectedSortOption = .mktCapDesc
    }
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await derivativesRepository.ensureCacheLoaded()
        
        selectedSortOption = await storageManager.load(type: AppSettingKey.derivativesSortOption.rawValue) ?? .openInterestDesc
        
        if let derivatives = await derivativesRepository.cachedDerivatives[selectedSortOption.derivativesApiValue]?.data {
            self.derivatives = derivatives
        }
        
        if let bitcoin = await cryptoDetailRepository.cachedBitcoin?.data {
            self.bitcoin = bitcoin
        }
    }
    
    func setNewSortOption(newSortOption: SortOption) async {
        selectedSortOption = newSortOption
        await storageManager.save(type: AppSettingKey.derivativesSortOption.rawValue, data: selectedSortOption)
    }

    func getDerivatives(
        newSortOption: SortOption
    ) async {
        if newSortOption != selectedSortOption {
            self.derivatives.removeAll()
        }
        
        if newSortOption != selectedSortOption {
            await setNewSortOption(newSortOption: newSortOption)
        }
        
        if let derivatives = await derivativesRepository.getDerivatives(
            sortOption: newSortOption
        ) {
            self.derivatives = derivatives
        }
    }

    func getBitcoin() async {
        if let bitcoin = await cryptoDetailRepository.getBitcoin() {
            self.bitcoin = bitcoin
        }
    }
}
