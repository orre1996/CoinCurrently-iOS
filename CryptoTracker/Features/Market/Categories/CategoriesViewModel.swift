//
//  CategoriesViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-17.
//

import Foundation

@MainActor
protocol CategoriesViewModel {
    var categories: [CryptoCategory] { get }
    var multiplier: Double? { get }
    var bitcoin: CurrencyDataModel? { get }
    var selectedSortOption: SortOption { get set }

    func setStartData() async
    func getCategories(newSortOption: SortOption) async
    func getBitcoin() async
    func setNewSortOption(newSortOption: SortOption) async
}

@MainActor @Observable
final class CategoriesViewModelImp: CategoriesViewModel, ObservableObject {
    private(set) var categories = [CryptoCategory]()
    private(set) var multiplier: Double?
    private(set) var bitcoin: CurrencyDataModel?
    
    var selectedSortOption: SortOption = .mktCapDesc
    
    private let categoriesRepository: CategoriesRepository
    private let cryptoDetailRepository: CryptoDetailRepository
    private let storageManager: CachedStorageManager
    
    init(
        categoriesRepository: CategoriesRepository = CategoriesRepositoryImp.shared,
        cryptoDetailRepository: CryptoDetailRepositoryImp = CryptoDetailRepositoryImp.shared,
        storageManager: CachedStorageManager = CachedStorageManagerImp.shared
    ) {
        self.categoriesRepository = categoriesRepository
        self.cryptoDetailRepository = cryptoDetailRepository
        self.storageManager = storageManager
        
        self.selectedSortOption = .mktCapDesc
    }
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await categoriesRepository.ensureCacheLoaded()
        
        selectedSortOption = await storageManager.load(type: AppSettingKey.categoriesSortOption.rawValue) ?? .mktCapDesc
        if let categories = await categoriesRepository.cachedCategories[selectedSortOption.categoriesApiValue]?.data {
            self.categories = sortCategories(
                newSortOption: selectedSortOption,
                categories: categories
            )
        }
        
        if let bitcoin = await cryptoDetailRepository.cachedBitcoin?.data {
            self.bitcoin = bitcoin
            self.multiplier = calculatePriceMultiplier(from: bitcoin)
        }
    }
    
    func getCategories(
        newSortOption: SortOption
    ) async {
        if newSortOption != selectedSortOption {
            self.categories.removeAll()
        }
        
        if newSortOption != selectedSortOption {
            await setNewSortOption(newSortOption: newSortOption)
        }
        
        if let categories = await categoriesRepository.getCategories(
            sortOption: newSortOption
        ) {
            self.categories = sortCategories(
                newSortOption: newSortOption,
                categories: categories
            )
        }
    }
    
    func getBitcoin() async {
        if let bitcoin = await cryptoDetailRepository.getBitcoin() {
            self.bitcoin = bitcoin
            self.multiplier = calculatePriceMultiplier(from: bitcoin)
        }
    }
    
    func setNewSortOption(newSortOption: SortOption) async {
        selectedSortOption = newSortOption
        await storageManager.save(type: AppSettingKey.categoriesSortOption.rawValue, data: selectedSortOption)
    }
    
    private func calculatePriceMultiplier(from bitcoin: CurrencyDataModel) -> Double? {
        let selectedCurrency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        let targetPrice = bitcoin.market_data?.current_price?.getConvertedCurrency(selectedCurrency: selectedCurrency.code.uppercased()) ?? 0
        let basePrice = bitcoin.market_data?.current_price?.getConvertedCurrency(selectedCurrency: "USD") ?? 0
        
        guard basePrice > 0 else { return nil }
        return targetPrice / basePrice
    }
    
    private func sortCategories(
        newSortOption: SortOption,
        categories: [CryptoCategory]
    ) -> [CryptoCategory] {
        switch newSortOption {
        case .nameDesc:
            return categories.sorted(by: { ($0.name?.trimmingCharacters(in: .whitespaces) ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedDescending })
        case .nameAsc:
            return categories.sorted(by: { ($0.name?.trimmingCharacters(in: .whitespaces) ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending })
        default:
            return categories
        }
    }
}
