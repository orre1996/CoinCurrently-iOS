//
//  ToplistViewModel.swift
//  Cryptocurrently
//
//  Created by Oscar Berggren on 2020-11-12.
//

import Foundation
import SwiftUI
import Combine

@MainActor
protocol ToplistViewModel {
    var toplist: [Toplist] { get }
    var favoritesList: [Toplist] { get }
    var category: CryptoCategory? { get }
    var selectedSortOption: SortOption { get set }
    var selectedPriceChangeOption: PriceChange { get set }

    func setStartData() async
    func setNewSortOption(newSortOption: SortOption) async
    func setNewPriceChangeOption(newPriceChangeOption: PriceChange)
    func getToplist(newSortOption: SortOption, newPriceChangeOption: PriceChange) async
    func favouriteButtonPressed(toplistItem: Toplist?) async
}

@MainActor @Observable
final class ToplistViewModelImp: ToplistViewModel, ObservableObject {
    private(set) var toplist = [Toplist]()
    private(set) var favoritesList = [Toplist]()
    private(set) var category: CryptoCategory?

    var selectedSortOption: SortOption = .mktCapDesc
    var selectedPriceChangeOption: PriceChange = .sevenDays

    private let toplistRepository: ToplistRepository
    private let trendingRepository: TrendingRepository
    private let winnersLosersRepository: WinnersLosersRepository
    private let cryptoDetailRepository: CryptoDetailRepository
    private let storageManager: CachedStorageManager
    private let analyticsManager: AnalyticsManager
    
    init(
        category: CryptoCategory? = nil,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        trendingRepository: TrendingRepository = TrendingRepositoryImp.shared,
        winnersLosersRepository: WinnersLosersRepository = WinnersLosersRepositoryImp.shared,
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared,
        storageManager: CachedStorageManager = CachedStorageManagerImp.shared,
        analyticsManager: AnalyticsManager = AnalyticsManager.shared
    ) {
        self.category = category
        self.toplistRepository = toplistRepository
        self.trendingRepository = trendingRepository
        self.winnersLosersRepository = winnersLosersRepository
        self.cryptoDetailRepository = cryptoDetailRepository
        self.storageManager = storageManager
        self.analyticsManager = analyticsManager
        
        self.selectedSortOption = .mktCapDesc
        self.selectedPriceChangeOption = .sevenDays
    }
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await toplistRepository.ensureCacheLoaded()
        await trendingRepository.ensureCacheLoaded()
        await winnersLosersRepository.ensureCacheLoaded()
        
        selectedSortOption = await storageManager.load(type: AppSettingKey.toplistSortOption.rawValue) ?? .mktCapDesc
        selectedPriceChangeOption = await storageManager.load(type: AppSettingKey.toplistPriceChange.rawValue) ?? .sevenDays
        
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        let cacheKey = "\(selectedSortOption.getOptionKey(priceChange: selectedPriceChangeOption))-\(category?.id ?? "")-\(currency.code)"
        if
            let toplist = await toplistRepository.cachedToplist[cacheKey]?.data,
            !toplist.isEmpty
        {
            self.toplist = toplist
        }
        
        if let favorites = await toplistRepository.cachedFavorites?.data, !favorites.isEmpty {
            self.favoritesList = favorites
        }
    }
    
    func setNewSortOption(newSortOption: SortOption) async {
        selectedSortOption = newSortOption
        await storageManager.save(type: AppSettingKey.toplistSortOption.rawValue, data: selectedSortOption)
    }
    
    func setNewPriceChangeOption(newPriceChangeOption: PriceChange) {
        selectedPriceChangeOption = newPriceChangeOption
        Task { await storageManager.save(type: AppSettingKey.toplistPriceChange.rawValue, data: selectedPriceChangeOption) }
    }

    func clearToplist() {
        toplist = []
    }

    func getToplist(
        newSortOption: SortOption,
        newPriceChangeOption: PriceChange
    ) async {
        if newSortOption != selectedSortOption || newPriceChangeOption != selectedPriceChangeOption {
            self.toplist.removeAll()
        }
        
        if newSortOption != selectedSortOption {
            await setNewSortOption(newSortOption: newSortOption)
        }
        
        if newPriceChangeOption != selectedPriceChangeOption {
            setNewPriceChangeOption(newPriceChangeOption: newPriceChangeOption)
        }
        
        if let toplist = await toplistRepository.getMarketToplist(
            sortOption: newSortOption,
            priceChange: newPriceChangeOption,
            platformId: category?.id
        ) {
            self.toplist = toplist
        }
    }

    func favouriteButtonPressed(toplistItem: Toplist?) async {
        guard let toplistItem = toplistItem else { return }

        let fromScreen: ScreenLabel = category != nil ? .categoryDetail : .market
        
        if favoritesList.contains(where: { $0.id == toplistItem.id }) {
            analyticsManager.log(FavoriteRemoved(coinName: toplistItem.name ?? "", fromScreen: fromScreen))
        } else {
            analyticsManager.log(FavoriteAdded(coinName: toplistItem.name ?? "", fromScreen: fromScreen))
        }

        favoritesList = await toplistRepository.favouriteButtonPressed(toplist: toplistItem)
    }
}
