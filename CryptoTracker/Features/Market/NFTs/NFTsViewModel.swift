//
//  NFTsViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-10-01.
//

import Foundation
import SwiftUI

@MainActor
protocol NFTsViewModel {
    var nftToplist: [NFTToplist] { get }
    var nftPlatforms: [NFTPlatform]? { get }
    var bitcoin: CurrencyDataModel? { get }
    var multiplier: Double? { get }
    var selectedSortOption: SortOption { get set }
    var selectedPlatform: NFTPlatform { get set }

    func setStartData() async
    func setNewSortOption(newSortOption: SortOption) async
    func setNewPlatform(newPlatform: NFTPlatform) async
    func getNftToplist(newPlatform: NFTPlatform, newSortOption: SortOption) async
    func getNFTPlatforms() async
    func getBitcoin() async
    func getAllCoins() async
    func getChainSymbol(for nativeCurrency: String?) -> CurrencyModel?
}

@MainActor @Observable
final class NFTsViewModelImp: NFTsViewModel, ObservableObject {
    private var coinsList = [CoinsListModel]()
    private var chainSymbolLookup: [String: String] = [:]

    private(set) var nftToplist = [NFTToplist]()
    private(set) var nftPlatforms: [NFTPlatform]?
    private(set) var bitcoin: CurrencyDataModel?
    private(set) var multiplier: Double?

    var selectedSortOption: SortOption = .mktCapFiatDesc
    var selectedPlatform: NFTPlatform

    private let nftRepository: NFTRepository
    private let globalMarketRepository: GlobalMarketRepository
    private let cryptoDetailRepository: CryptoDetailRepository
    private let storageManager: CachedStorageManager
    
    init(
        nftRepository: NFTRepository = NFTRepositoryImp.shared,
         globalMarketRepository: GlobalMarketRepository = GlobalMarketRepositoryImp.shared,
         cryptoDetailRepository: CryptoDetailRepositoryImp = CryptoDetailRepositoryImp.shared,
         storageManager: CachedStorageManager = CachedStorageManagerImp.shared
    ) {
        self.nftRepository = nftRepository
        self.globalMarketRepository = globalMarketRepository
        self.cryptoDetailRepository = cryptoDetailRepository
        self.storageManager = storageManager
    
        self.selectedSortOption = .mktCapFiatDesc
        self.selectedPlatform = NFTPlatform(id: "all", name: "All Chains", image: nil)
    }
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await nftRepository.ensureCacheLoaded()
        await globalMarketRepository.ensureCacheLoaded()
        
        selectedSortOption = await storageManager.load(type: AppSettingKey.nftsSortOption.rawValue) ?? .mktCapFiatDesc
        selectedPlatform = await storageManager.load(type: AppSettingKey.nftPlatform.rawValue) ?? NFTPlatform(id: "all", name: "All Chains", image: nil)
        if let nftToplist = await nftRepository.cachedToplist["\(selectedSortOption.nftApiValue)-\(selectedPlatform.id ?? "")"]?.data {
            self.nftToplist = sortToplist(sortOption: selectedSortOption, toplist: nftToplist)
        }
        
        if let platforms = await nftRepository.cachedPlatforms?.data {
            self.nftPlatforms = sortPlatforms(platforms: platforms)
        }
        
        if let bitcoin = await cryptoDetailRepository.cachedBitcoin?.data {
            self.bitcoin = bitcoin
            self.multiplier = calculatePriceMultiplier(from: bitcoin)
        }
        
        if let coinsList = await globalMarketRepository.cachedCoinList?.data {
            self.coinsList = coinsList
            buildChainSymbolLookup()
        }
    }
    
    func setNewSortOption(newSortOption: SortOption) async {
        selectedSortOption = newSortOption
        await storageManager.save(type: AppSettingKey.nftsSortOption.rawValue, data: selectedSortOption)
    }
    
    func setNewPlatform(newPlatform: NFTPlatform) async {
        selectedPlatform = newPlatform
        await storageManager.save(type: AppSettingKey.nftPlatform.rawValue, data: selectedPlatform)
    }
    
    func getNftToplist(
        newPlatform: NFTPlatform,
        newSortOption: SortOption,
    ) async {
        if newPlatform != selectedPlatform || newSortOption != selectedSortOption {
            nftToplist.removeAll()
        }
        
        if newSortOption != selectedSortOption {
            await setNewSortOption(newSortOption: newSortOption)
        }
        
        if newPlatform != selectedPlatform {
            await setNewPlatform(newPlatform: newPlatform)
        }
        
        if let nftToplist = await nftRepository.getToplist(
            platform: newPlatform,
            sortOption: newSortOption
        ) {
            self.nftToplist = sortToplist(sortOption: newSortOption, toplist: nftToplist)
        }
    }
    
    func getNFTPlatforms() async {
        if let platforms = await nftRepository.getNFTPlatforms() {
            self.nftPlatforms = sortPlatforms(platforms: platforms)
        }
    }

    func getBitcoin() async {
        if let bitcoin = await cryptoDetailRepository.getBitcoin() {
            self.bitcoin = bitcoin
            self.multiplier = calculatePriceMultiplier(from: bitcoin)
        }
    }
    
    func getAllCoins() async {
        if let allCoins = await globalMarketRepository.getAllCoins() {
            self.coinsList = allCoins
            buildChainSymbolLookup()
        }
    }

    func getChainSymbol(for nativeCurrency: String?) -> CurrencyModel? {
        guard let currency = nativeCurrency?.lowercased() else { return
            nil
        }
        
        guard let symbol = chainSymbolLookup[currency] else {
            return nil
        }

        return CurrencyModel(
            currency: " \(symbol)",
            code: " \(symbol)",
            symbol: " \(symbol)",
            suffix: true
        )
    }
    
    private func sortToplist(sortOption: SortOption, toplist: [NFTToplist]) -> [NFTToplist] {
        switch sortOption {
        case .floorPriceDesc:
            return toplist.sorted { ($0.floor_price?.usd ?? 0) > ($1.floor_price?.usd ?? 0) }
        case .floorPriceAsc:
            return toplist.sorted { ($0.floor_price?.usd ?? 0) < ($1.floor_price?.usd ?? 0) }
        case .floorPriceChangeDesc:
            return toplist.sorted { ($0.floor_price_in_usd_24h_percentage_change ?? 0) > ($1.floor_price_in_usd_24h_percentage_change ?? 0) }
        case .floorPriceChangeAsc:
            return toplist.sorted { ($0.floor_price_in_usd_24h_percentage_change ?? 0) < ($1.floor_price_in_usd_24h_percentage_change ?? 0) }
        default:
            return toplist
        }
    }
    
    private func sortPlatforms(platforms: [NFTPlatform]) -> [NFTPlatform] {
        return [NFTPlatform(id: "all", name: "All Chains", image: nil)] + platforms.sorted(by: { ($0.name ?? "") < ($1.name ?? "") })
    }
    
    private func buildChainSymbolLookup() {
        var lookup: [String: String] = [:]
        for coin in coinsList {
            guard let symbol = coin.symbol?.uppercased() else {
                continue
            }
            if let id = coin.id?.lowercased() {
                lookup[id] = symbol
            }
            if let name = coin.name?.lowercased() {
                lookup[name] = symbol
            }
        }
        chainSymbolLookup = lookup
    }

    private func calculatePriceMultiplier(from bitcoin: CurrencyDataModel) -> Double? {
        let selectedCurrency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        let targetPrice = bitcoin.market_data?.current_price?.getConvertedCurrency(selectedCurrency: selectedCurrency.code.uppercased()) ?? 0
        let basePrice = bitcoin.market_data?.current_price?.getConvertedCurrency(selectedCurrency: "USD") ?? 0

        guard basePrice > 0 else { return nil }
        return targetPrice / basePrice
    }
}
