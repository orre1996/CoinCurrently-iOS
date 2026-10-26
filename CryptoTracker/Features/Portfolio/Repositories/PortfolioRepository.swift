//
//  PortfolioRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-24.
//

import Foundation
import SwiftUI
import UIKit
import Combine

// Note: CachedPortfolioPies has extra fields so it remains a custom struct
struct CachedPortfolioPies: Codable {
    var data: [Pie]
    var otherCoins: [Toplist]
    var coinColors: [String: String]
    var date: Date

    init(
        data: [Pie],
        otherCoins: [Toplist],
        coinColors: [String: String] = [:],
        date: Date
    ) {
        self.data = data
        self.otherCoins = otherCoins
        self.coinColors = coinColors
        self.date = date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode([Pie].self, forKey: .data)
        otherCoins = try container.decode([Toplist].self, forKey: .otherCoins)
        coinColors = try container.decodeIfPresent([String: String].self, forKey: .coinColors) ?? [:]
        date = try container.decode(Date.self, forKey: .date)
    }
}

protocol PortfolioRepository: Actor {
    var cachedPortfolioPies: CachedPortfolioPies? { get }
    var cachedPortfolioPrices: CachedData<[Cryptocurrency]>? { get }
    var portfolioModels: [PortfolioModel] { get }
    
    func ensureCacheLoaded() async
    func migratePortfolio() async
    func resetData(onlyPies: Bool)
    func getPortfolio() async -> CachedPortfolioPies?
    func refreshWallets() async -> CachedPortfolioPies?
    func getPortfolioAllCurrencies() async -> [Cryptocurrency]?
    func renameWallet(id: String, address: String, newName: String) async
    func importWallet(walletName: String?, coinData: CurrencyDataModel?, address: String, chain: Chain, isRefreshing: Bool) async -> (CachedPortfolioPies?, [Cryptocurrency]?)
    func addNewCoin(coin: Toplist, event: any PortfolioEvent, allCurrencies: [String: Double]?) async
    func addNewTransaction(id: String, event: any PortfolioEvent) async
    func deletePortfolioItem(id: String) async
    func deleteTransaction(id: String, uuid: UUID?) async -> CachedPortfolioPies?
    /// Resolves transaction id (UUID string), swap id, or imported wallet address to an event and its coin.
    func findTransaction(lookup: String) async -> ((any PortfolioEvent)?, Toplist?)
    func getCoinColors() async -> AsyncStream<[Pie]>
}

final actor PortfolioRepositoryImp: PortfolioRepository {
    static let shared = PortfolioRepositoryImp()
    
    private let networkManager: NetworkManager
    private let coreDataManager: CoreDataManager

    private(set) var cachedPortfolioPies: CachedPortfolioPies?
    private(set) var cachedPortfolioPrices: CachedData<[Cryptocurrency]>?
    private(set) var portfolioModels: [PortfolioModel] = []

    init(
        networkManager: NetworkManager = NetworkManagerImp.shared,
        coreDataManager: CoreDataManager = CoreDataManager.shared
    ) {
        self.networkManager = networkManager
        self.coreDataManager = coreDataManager
        
        self.cachedPortfolioPies = nil
        self.cachedPortfolioPrices = nil
    }
    
    private var hasLoadedFromStorage = false
    
    func ensureCacheLoaded() async {
#if IS_WIDGET
        await loadFromStorage()
#else
        guard !hasLoadedFromStorage else {
            return
        }
        hasLoadedFromStorage = true
        await loadFromStorage()
#endif
    }
    
    private func loadFromStorage() async {
        portfolioModels = await coreDataManager.get(forKey: .portfolio) ?? []
        await migratePortfolioCacheFromStorageIfNeeded()
        cachedPortfolioPies = await coreDataManager.get(forKey: .portfolioPies) ?? CachedPortfolioPies(data: [], otherCoins: [], date: Date.tenYearsAgo)
        cachedPortfolioPrices = await coreDataManager.get(forKey: .portfolioPrices) ?? CachedData(data: [], date: Date.tenYearsAgo)
    }
    
    private func migratePortfolioCacheFromStorageIfNeeded() async {
        let hasCoreDataPies = await coreDataManager.contains(key: .portfolioPies)
        guard !hasCoreDataPies else { return }
        if let pies: CachedPortfolioPies = await CachedStorageManagerImp.shared.load(type: LocalStorageKeys.portfolioPies) {
            await coreDataManager.set(pies, forKey: .portfolioPies)
        }
        if let prices: CachedData<[Cryptocurrency]> = await CachedStorageManagerImp.shared.load(type: LocalStorageKeys.portfolioPrices) {
            await coreDataManager.set(prices, forKey: .portfolioPrices)
        }
        if let date: Date = await CachedStorageManagerImp.shared.load(type: LocalStorageKeys.walletRefreshDate) {
            await coreDataManager.set(date, forKey: .walletRefreshDate)
        }
    }
    
    func migratePortfolio() async {
        await ensureCacheLoaded()
        let saved: [PortfolioModel] = await coreDataManager.get(forKey: .portfolio) ?? []
        let old = WidgetReloadService.shared.getSavedPortfolio()
        
        guard !old.isEmpty, saved.isEmpty else { return }
        
        portfolioModels = old.map { $0.migrateToNewPortfolioModel() }
        await coreDataManager.set(portfolioModels, forKey: .portfolio)
    }

    func resetData(onlyPies: Bool = false) {
        cachedPortfolioPies = nil
        cachedPortfolioPrices = nil
        hasLoadedFromStorage = false
    }
    
    func getPortfolio() async -> CachedPortfolioPies? {
        await ensureCacheLoaded()

        if let cachedPortfolioPies, !cachedPortfolioPies.date.defaultCacheTimer() {
            return cachedPortfolioPies
        }
        
        let ids = portfolioModels.allIds
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        
        guard
            !ids.isEmpty,
            let coins: [Toplist] = await networkManager.get(
                endpoint: .multipleCoins(
                    ids: ids,
                    withSparkline: true,
                    currency: currency
                )
            )
        else {
            return nil
        }
        
        var tempPortfolio = [Pie]()
        var tempOtherCoins = [Toplist]()
        let existingPies = cachedPortfolioPies?.data ?? []
        let preservedCoinColors = cachedPortfolioPies?.coinColors ?? [:]

        for coin in coins {
            if let portfolioModel = self.portfolioModels.first(where: { $0.id == coin.id }) {
                let preservedColor = preservedCoinColor(
                    coinId: coin.id,
                    existingPies: existingPies,
                    coinColors: preservedCoinColors
                )
                tempPortfolio.append(
                    Pie(
                        data: coin,
                        color: preservedColor,
                        transactions: portfolioModel.transactions,
                        swaps: portfolioModel.swaps,
                        imports: portfolioModel.imports
                    )
                )
            } else {
                tempOtherCoins.append(coin)
            }
        }

        let updated = CachedPortfolioPies(
            data: tempPortfolio,
            otherCoins: tempOtherCoins,
            coinColors: preservedCoinColors,
            date: Date()
        )
        cachedPortfolioPies = updated
        await coreDataManager.set(updated, forKey: .portfolioPies)

        return cachedPortfolioPies
    }
    
    func refreshWallets() async -> CachedPortfolioPies?  {
        await ensureCacheLoaded()
        if let walletRefreshDate: Date = await coreDataManager.get(forKey: .walletRefreshDate), !walletRefreshDate.defaultCacheTimer() {
            return nil
        }
        
        await withTaskGroup(of: Void.self) { group in
            for wallet in cachedPortfolioPies?.data.allWallets ?? [] {
                group.addTask {
                    _ = await self.importWallet(
                        walletName: wallet.walletName,
                        coinData: nil,
                        address: wallet.address,
                        chain: wallet.blockChain,
                        isRefreshing: true
                    )
                }
            }
            
            for await _ in group { }
        }

        await coreDataManager.set(Date(), forKey: .walletRefreshDate)
        return cachedPortfolioPies
    }

    func getPortfolioAllCurrencies() async -> [Cryptocurrency]? {
        await ensureCacheLoaded()

        if let cached = cachedPortfolioPrices, !cached.date.defaultCacheTimer() {
            return cached.data
        }
        
        let ids = portfolioModels.allIds
        
        guard
            !ids.isEmpty,
            let allPrices: CurrencyPricesAllCurrencies = await networkManager.get(endpoint: .coinsWithCurrencies(ids: ids))
        else {
            return nil
        }
        
        await updatePriceCache(with: allPrices.cryptocurrencies)
        return allPrices.cryptocurrencies
    }
    
    func renameWallet(
        id: String,
        address: String,
        newName: String
    ) async {
        guard
            var portfolio = cachedPortfolioPies,
            let index = portfolio.data.firstIndex(where: { $0.data?.id == id }),
            let importIndex = portfolio.data[index].imports.firstIndex(where: { $0.address == address })
        else {
            return
        }
        
        portfolio.data[index].imports[importIndex].walletName = newName
        
        await updatePortfolioPersistence(portfolio)
    }
    
    func importWallet(
        walletName: String?,
        coinData: CurrencyDataModel?,
        address: String,
        chain: Chain,
        isRefreshing: Bool = false
    ) async -> (CachedPortfolioPies?, [Cryptocurrency]?) {
        await ensureCacheLoaded()
        let (wallet, _): (AddressImport?, Int) = await networkManager.post(
            endpoint: .walletImport,
            bodyStruct: [
                "address": address,
                "blockChain": chain.rawValue.lowercased()
            ]
        )
        
        guard let cached = cachedPortfolioPies else {
            return (nil, nil)
        }

        let chainId = chain.id.lowercased()
        let coin = cached.data.first { $0.data?.id?.lowercased() == chainId }
        let existingImport = cached.data
            .compactMap { $0.imports.first(where: { $0.address == address }) }
            .first

        let walletName = walletName ?? portfolioModels.defaultWalletName
        guard let wallet = wallet?.copy(
            with: walletName,
            blockChain: chain, date: existingImport?.date,
            coinId: chain.id
        ) else {
            return (nil, nil)
        }
        
        if let id = coin?.data?.id, let existingImport {
            await addNewTransaction(id: id, event: wallet.copy(with: wallet.date))
            _ = await deleteTransaction(id: id, uuid: existingImport.id)
        } else if let id = coin?.data?.id {
            await addNewTransaction(id: id, event: wallet)
        } else if let coinData {
            await addNewCoin(
                coin: coinData.toToplist(),
                event: wallet,
                allCurrencies: coinData.market_data?.current_price
            )
        }
        
        if let tokenInfos = wallet.tokenInfos,
           let cached = cachedPortfolioPies
        {
            let existingIds = Set(
                cached.data.compactMap { $0.data?.id } +
                cached.otherCoins.map { $0.id }
            )
            
            let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
            let coinIds = tokenInfos
                .compactMap { $0.tokenId }
                .filter { id in
                    if isRefreshing {
                        return !existingIds.contains(id)
                    } else {
                        return true
                    }
                }
            
            if !coinIds.isEmpty,
               let coins: [Toplist] = await networkManager.get(
                endpoint: .multipleCoins(
                    ids: coinIds,
                    withSparkline: true,
                    currency: currency
                )
               )
            {
                var updatedCache = cached
                
                for coin in coins {
                    if let index = updatedCache.otherCoins.firstIndex(where: { $0.id == coin.id }) {
                        updatedCache.otherCoins[index] = coin
                    } else if !(updatedCache.data.contains { $0.data?.id == coin.id }) {
                        updatedCache.otherCoins.append(coin)
                    }
                    
                    if let id = coin.id, let price = coin.current_price {
                        let selectedCurrency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
                        
                        await upsertPrice(
                            for: id,
                            currencies: [selectedCurrency.code.lowercased() : price]
                        )
                    }
                }
                
                await updatePortfolioCache(with: updatedCache)
            }
        }
        
        return (cachedPortfolioPies, cachedPortfolioPrices?.data)
    }
    
    func addNewCoin(
        coin: Toplist,
        event: any PortfolioEvent,
        allCurrencies: [String: Double]?
    ) async {
        await ensureCacheLoaded()
        guard let id = coin.id else { return }

        let resolvedCoin = await resolvedCoin(with: coin)
        let color = await colorHex(from: resolvedCoin.image)

        if let event = event as? PortfolioTransaction {
            let newPie = Pie(data: resolvedCoin, color: color, transactions: [event])
            await appendPie(newPie)
        } else if let event = event as? PortfolioSwapTransaction {
            let newPie = Pie(data: resolvedCoin, color: color, swaps: [event])
            await appendPie(newPie)
        }  else if let event = event as? AddressImport {
            let newPie = Pie(data: resolvedCoin, color: color, imports: [event])
            await appendPie(newPie)
        }

        if let allCurrencies {
            await upsertPrice(
                for: id,
                currencies: allCurrencies
            )
        } else {
            await coreDataManager.set(
                CachedData(data: cachedPortfolioPrices?.data ?? [], date: Date.tenYearsAgo),
                forKey: .portfolioPrices
            )
        }
    }
    
    func addNewTransaction(
        id: String,
        event: any PortfolioEvent
    ) async {
        await ensureCacheLoaded()
        guard
            var portfolio = cachedPortfolioPies,
            let index = portfolio.data.firstIndex(where: { $0.data?.id == id })
        else {
            return
        }
        
        switch event {
        case let event as PortfolioTransaction:
            portfolio.data[index].transactions.append(event)
        case let event as PortfolioSwapTransaction:
            portfolio.data[index].swaps.append(event)
        case let event as AddressImport:
            portfolio.data[index].imports.append(event)
        default:
            return
        }

        await updatePortfolioPersistence(portfolio)
    }

    func deletePortfolioItem(id: String) async {
        await ensureCacheLoaded()
        guard
            var portfolio = cachedPortfolioPies,
            let index = portfolio.data.firstIndex(where: { $0.data?.id == id })
        else {
            return
        }
        
        portfolio.data.remove(at: index)
        await updatePortfolioPersistence(portfolio)
    }

    func deleteTransaction(
        id: String,
        uuid: UUID?
    ) async -> CachedPortfolioPies? {
        await ensureCacheLoaded()
        guard
            var portfolio = cachedPortfolioPies,
            let index = portfolio.data.firstIndex(where: { $0.data?.id == id })
        else {
            return cachedPortfolioPies
        }
        
        portfolio.data[index].transactions.removeAll { $0.id == uuid }
        portfolio.data[index].swaps.removeAll { $0.id == uuid }
        portfolio.data[index].imports.removeAll { $0.id == uuid }
        
        portfolio.otherCoins.removeAll { coin in
            portfolio.data.getAllTransactions(of: coin.id).isEmpty
        }
        
        if portfolio.data[index].transactions.isEmpty &&
            portfolio.data[index].swaps.isEmpty &&
            portfolio.data[index].imports.isEmpty {
            portfolio.data.remove(at: index)
        }
        
        await updatePortfolioPersistence(portfolio)
        return portfolio
    }

    func findTransaction(lookup: String) async -> ((any PortfolioEvent)?, Toplist?) {
        await ensureCacheLoaded()
        let portfolio = cachedPortfolioPies?.data

        for pie in portfolio ?? [] {
            if let event = pie.transactions.first(where: { $0.id == UUID(uuidString: lookup) }) {
                return (event, pie.data)
            }
            if let event = pie.swaps.first(where: { $0.id == UUID(uuidString: lookup) }) {
                return (event, pie.data)
            }
            if let event = pie.imports.first(where: { $0.address == lookup }) {
                return (event, pie.data)
            }
        }
        return (nil, nil)
    }

    func getCoinColors() -> AsyncStream<[Pie]> {
        return AsyncStream<[Pie]>(bufferingPolicy: .unbounded) { continuation in
            Task {
                await ensureCacheLoaded()

                guard var portfolio = cachedPortfolioPies,
                      !(portfolio.data.isEmpty && portfolio.otherCoins.isEmpty) else {
                    continuation.finish()
                    return
                }

                struct ColorTarget {
                    let id: String
                    let imageURL: String
                    let isOtherCoin: Bool
                }

                var colorTargets: [ColorTarget] = []

                for pie in portfolio.data {
                    guard needsCoinColor(pie.color),
                          let id = pie.data?.id,
                          let imageURL = pie.data?.image else {
                        continue
                    }
                    colorTargets.append(ColorTarget(id: id, imageURL: imageURL, isOtherCoin: false))
                }

                for coin in portfolio.otherCoins {
                    guard let id = coin.id,
                          let imageURL = coin.image else {
                        continue
                    }

                    let existingColor = portfolio.data.first(where: { $0.data?.id == id })?.color
                        ?? portfolio.coinColors[id]

                    guard needsCoinColor(existingColor) else {
                        continue
                    }

                    colorTargets.append(ColorTarget(id: id, imageURL: imageURL, isOtherCoin: true))
                }

                guard !colorTargets.isEmpty else {
                    continuation.yield(portfolio.data)
                    continuation.finish()
                    return
                }

                await withTaskGroup(of: (String, Bool, Data?).self) { taskGroup in
                    for target in colorTargets {
                        taskGroup.addTask {
                            (target.id, target.isOtherCoin, await self.networkManager.get(endpoint: .image(url: target.imageURL)))
                        }
                    }

                    for await result in taskGroup where result.2 != nil {
                        let coinId = result.0
                        let isOtherCoin = result.1
                        let imageData = result.2

                        if let imageData, let image = UIImage(data: imageData) {
                            let color = colorHex(from: image)

                            if isOtherCoin {
                                portfolio.coinColors[coinId] = color
                            } else if let index = portfolio.data.firstIndex(where: { $0.data?.id == coinId }) {
                                portfolio.data[index].color = color
                            }

                            continuation.yield(portfolio.data)
                        }
                    }
                }

                let cacheDate = cachedPortfolioPies?.date ?? Date()
                cachedPortfolioPies = CachedPortfolioPies(
                    data: portfolio.data,
                    otherCoins: portfolio.otherCoins,
                    coinColors: portfolio.coinColors,
                    date: cacheDate
                )
                await coreDataManager.set(cachedPortfolioPies, forKey: .portfolioPies)
                continuation.finish()
            }
        }
    }

    // MARK: - Helpers
    private func resolvedCoin(with coin: Toplist) async -> Toplist {
        guard coin.image == nil, let id = coin.id else { return coin }

        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        guard let coins: [Toplist] = await networkManager.get(
            endpoint: .multipleCoins(
                ids: [id],
                currency: currency
            )
        ), let fetchedCoin = coins.first else {
            return coin
        }

        return fetchedCoin
    }

    private func colorHex(from imageURL: String?) async -> String? {
        guard let imageURL else { return nil }
        guard let imageData: Data = await networkManager.get(endpoint: .image(url: imageURL)),
              let image = UIImage(data: imageData) else {
            return nil
        }

        return colorHex(from: image)
    }

    private func colorHex(from image: UIImage) -> String {
        Color(image.getColors(quality: .high).background).hexStringFromColor()
    }

    private func needsCoinColor(_ color: String?) -> Bool {
        guard let color else { return true }
        return color.uppercased() == "#FFFFFF"
    }

    private func preservedCoinColor(
        coinId: String?,
        existingPies: [Pie],
        coinColors: [String: String]
    ) -> String? {
        guard let coinId else { return nil }

        let pieColor = existingPies.first(where: { $0.data?.id == coinId })?.color
        if !needsCoinColor(pieColor) {
            return pieColor
        }

        let cachedColor = coinColors[coinId]
        if !needsCoinColor(cachedColor) {
            return cachedColor
        }

        return nil
    }

    private func updatePortfolioCache(with portfolio: CachedPortfolioPies) async {
        let updated = CachedPortfolioPies(
            data: portfolio.data,
            otherCoins: portfolio.otherCoins,
            coinColors: portfolio.coinColors,
            date: cachedPortfolioPies?.date ?? Date()
        )
        cachedPortfolioPies = updated
        await coreDataManager.set(updated, forKey: .portfolioPies)
    }
    
    private func updatePriceCache(with prices: [Cryptocurrency]) async {
        let updated = CachedData(data: prices, date: .now)
        cachedPortfolioPrices = updated
        await coreDataManager.set(updated, forKey: .portfolioPrices)
    }
    
    private func upsertPrice(
        for id: String,
        currencies: [String: Double]
    ) async {
        guard var prices = cachedPortfolioPrices else { return }
        if let index = prices.data.firstIndex(where: { $0.id == id }) {
            var existing = prices.data[index].prices
            currencies.forEach { key, value in
                existing[key] = value
            }
            prices.data[index].prices = existing
        } else {
            prices.data.append(.init(id: id, prices: currencies))
        }
        cachedPortfolioPrices = prices
        await coreDataManager.set(prices, forKey: .portfolioPrices)
    }
    
    private func appendPie(_ pie: Pie) async {
        guard var portfolio = cachedPortfolioPies else {
            return
        }

        portfolio.data.append(pie)
        cachedPortfolioPies = CachedPortfolioPies(
            data: portfolio.data,
            otherCoins: portfolio.otherCoins,
            coinColors: portfolio.coinColors,
            date: cachedPortfolioPies?.date ?? Date.tenYearsAgo
        )
        await coreDataManager.set(cachedPortfolioPies, forKey: .portfolioPies)
        await updatePortfolioPersistence(portfolio)
    }
    
    private func updatePortfolioPersistence(_ portfolio: CachedPortfolioPies) async {
        await updatePortfolioCache(with: portfolio)
        await coreDataManager.set(portfolio.data.compactMap { $0.toPortfolioCurrencyModel }, forKey: .portfolio)
        portfolioModels = await coreDataManager.get(forKey: .portfolio) ?? []
        WidgetReloadService.shared.forceUpdateWidgets(type: .portfolio)
    }
}
