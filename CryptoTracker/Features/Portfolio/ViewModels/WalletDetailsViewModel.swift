//
//  WalletDetailsViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 12/17/25.
//

import SwiftUI
import Combine

@MainActor
protocol WalletDetailsViewModel {
    var coins: [Toplist]? { get }
    var allPrices: [Cryptocurrency] { get }
    var sortedTokens: [TokenInfo] { get }

    var wallet: AddressImport { get set }
    var coin: Toplist { get }
    var isDoneSorting: Bool { get }

    var hideData: Bool { get set }

    var totalValue: Double? { get }
    var changePercent: Double? { get }
    var changeValue: Double? { get }

    func setStartData() async
    func getAllPortfolioCurrencies() async
    func getCoins() async

    func toggleHideData()
    func deleteWallet() async
    func renameWallet(newName: String) async
}

@MainActor @Observable
final class WalletDetailsViewModelImp: WalletDetailsViewModel {
    
    private let portfolioRepository: PortfolioRepository
    private let priceAlertsRepository: PriceAlertsRepository
    private let settingsManager: SettingsManager
    private let coreDataManager: CoreDataManager
    
    private(set) var coins: [Toplist]? = []
    private(set) var allPrices = [Cryptocurrency]()
    private(set) var sortedTokens: [TokenInfo] = []
    
    var wallet: AddressImport
    let coin: Toplist
    var syncedDate: Date? = nil
    var isDoneSorting: Bool = false

    var hideData: Bool

    init(
        portfolioRepository: PortfolioRepository = PortfolioRepositoryImp.shared,
        priceAlertsRepository: PriceAlertsRepository = PriceAlertsRepositoryImp.shared,
        settingsManager: SettingsManager = SettingsManager.shared,
        coreDataManager: CoreDataManager = CoreDataManager.shared,
        wallet: AddressImport,
        coin: Toplist
    ) {
        self.portfolioRepository = portfolioRepository
        self.priceAlertsRepository = priceAlertsRepository
        self.settingsManager = settingsManager
        self.coreDataManager = coreDataManager
        
        self.wallet = wallet
        self.coin = coin
        
        self.hideData = settingsManager.get(key: AppSettingKey.hidePortfolioValues) ?? false
    }
    
    func setStartData() async {
        await portfolioRepository.ensureCacheLoaded()
        await priceAlertsRepository.ensureCacheLoaded()
        
        if let cachedPrices = await portfolioRepository.cachedPortfolioPrices?.data {
            allPrices = cachedPrices
        }
        
        self.syncedDate = await coreDataManager.get(forKey: .walletRefreshDate) ?? Date()
    
        sortTokens()
    }
    
    var totalValue: Double? {
        return wallet.totalValue(
            mainId: coin.id,
            prices: allPrices
        )
    }

    var changePercent: Double? {
        guard
            let changeValue,
            let totalValue
        else {
            return nil
        }

        let previousValue = totalValue - changeValue
        guard previousValue != 0 else {
            return 0
        }

        return (changeValue / previousValue) * 100
    }
    
    var changeValue: Double? {
        guard let totalValue, let previousValue = calculatePreviousValue(
            coins: coins,
            wallet: wallet
        ) else {
            return nil
        }

        return totalValue - previousValue
    }
    
    func previousPrice(current: Double, percentChange: Double) -> Double? {
        let change = percentChange / 100
        let denominator = 1 + change
        guard denominator > 0 else { return nil }
        return current / denominator
    }
    
    func toggleHideData() {
        hideData.toggle()
        settingsManager.set(data: hideData, key: AppSettingKey.hidePortfolioValues)
    }
    
    func deleteWallet() async {
        guard let id = coin.id else {
            return
        }

        _ = await portfolioRepository.deleteTransaction(id: id, uuid: wallet.id)
    }
    
    func renameWallet(newName: String) async {
        guard let id = coin.id else {
            return
        }
        
        wallet.walletName = newName
        await portfolioRepository.renameWallet(
            id: id,
            address: wallet.address,
            newName: newName
        )
    }
    
    func calculatePreviousValue(
        coins: [Toplist]?,
        wallet: AddressImport
    ) -> Double? {
        guard let coins else {
            return nil
        }
        
        var total = 0.0

        if
            let coinId = wallet.coinId,
            let coin = coins.first(where: { $0.id == coinId }),
            let currentPrice = coin.current_price,
            let balance = Double(wallet.balance),
            let prevPrice = previousPrice(
                current: currentPrice,
                percentChange: coin.price_change_percentage_7d_in_currency ?? 0
            )
        {
            total += prevPrice * balance
        }

        for token in wallet.tokenInfos ?? [] {
            guard
                let tokenId = token.tokenId,
                let coin = coins.first(where: { $0.id == tokenId }),
                let currentPrice = coin.current_price,
                let balance = Double(token.balance),
                let prevPrice = previousPrice(
                    current: currentPrice,
                    percentChange: coin.price_change_percentage_7d_in_currency ?? 0
                )
            else {
                continue
            }

            total += prevPrice * balance
        }

        return total
    }
    
    func getAllPortfolioCurrencies() async {
        if let allCurrencies = await portfolioRepository.getPortfolioAllCurrencies() {
            allPrices = allCurrencies
        }
    }
    
    func getCoins() async {
        if let coins = await priceAlertsRepository.downloadRemainingCoins(ids: wallet.allIds, withSparkline: true) {
            self.coins = coins
            
            sortTokens()
        }
        
        isDoneSorting = true
    }
    
    func sortTokens() {
        let prices: [String: Double] = coins?.reduce(into: [:]) {
            if let id = $1.id, let price = $1.current_price {
                $0[id] = price
            }
        } ?? [:]
        
        sortedTokens = (wallet.tokenInfos ?? []).sorted {
            let balance1 = ((Double($0.balance) ?? 0) * (prices[$0.tokenId ?? ""] ?? 0))
            let balance2 = ((Double($1.balance) ?? 0) * (prices[$1.tokenId ?? ""] ?? 0))
            return balance1 > balance2
        }
        
        isDoneSorting = true
    }
}
