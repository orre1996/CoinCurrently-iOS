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
    private let storeKitManager: StoreKitManager
    private let storageManager: CachedStorageManager
    private let analyticsManager: AnalyticsManager
    
    init(
        category: CryptoCategory? = nil,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        trendingRepository: TrendingRepository = TrendingRepositoryImp.shared,
        winnersLosersRepository: WinnersLosersRepository = WinnersLosersRepositoryImp.shared,
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared,
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared,
        storageManager: CachedStorageManager = CachedStorageManagerImp.shared,
        analyticsManager: AnalyticsManager = AnalyticsManager.shared
    ) {
        self.category = category
        self.toplistRepository = toplistRepository
        self.trendingRepository = trendingRepository
        self.winnersLosersRepository = winnersLosersRepository
        self.cryptoDetailRepository = cryptoDetailRepository
        self.storeKitManager = storeKitManager
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
        
        let cacheKey = "\(selectedSortOption.getOptionKey(priceChange: selectedPriceChangeOption))-\(category?.id ?? "")"
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
            
            if category != nil {
                if
                    let secret: HiddenSecret = await FirebaseManagerImp.shared.getConfigJsonValue(key: .show_secret_message),
                    secret.secret_number == "3"
                {
                    self.toplist.insert(
                        Toplist(symbol: "Secret message", name: "CoinCurrently", image: secret.secret_image, current_price: 123.45, market_cap_rank: 0, price_change_percentage_1h_in_currency: 99.99, price_change_percentage_24h_in_currency: 99.99, price_change_percentage_7d_in_currency: 99.99, price_change_percentage_30d_in_currency: 99.99, market_cap: 123450
                               ), at: 12)
                }
            }
        }
    }

    func favouriteButtonPressed(toplistItem: Toplist?) async {
        guard let toplistItem = toplistItem else { return }

        let hasActiveSubscription = await storeKitManager.currentSubscription != nil
        let fromScreen: ScreenLabel = category != nil ? .categoryDetail : .market
        
        if !hasActiveSubscription && !favoritesList.contains(where: { $0.id == toplistItem.id }) && favoritesList.count >= 2 {
            analyticsManager.log(
                BuyProOpened(fromScreen: fromScreen, action: .Favorite)
            )
            showBuyPro()
            return
        }
        
        if favoritesList.contains(where: { $0.id == toplistItem.id }) {
            analyticsManager.log(FavoriteRemoved(coinName: toplistItem.name ?? "", fromScreen: fromScreen))
        } else {
            analyticsManager.log(FavoriteAdded(coinName: toplistItem.name ?? "", fromScreen: fromScreen))
        }

        favoritesList = await toplistRepository.favouriteButtonPressed(toplist: toplistItem)
    }
}
