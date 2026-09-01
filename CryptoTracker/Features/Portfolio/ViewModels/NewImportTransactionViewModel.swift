//
//  NewTransactionViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-08-30.
//

import SwiftUI
import Combine

@MainActor
protocol NewImportTransactionViewModel {
    var walletName: String { get set }
    var address: String { get set }
    var selectedChain: Chain { get set }
    var isImporting: Bool { get }
    var showImportError: Bool { get }
    var chainCoins: [Toplist]? { get }

    func getToplist() async
    func importWallet() async -> Bool
}

@MainActor @Observable
final class NewImportTransactionViewModelImp: NewImportTransactionViewModel {
    private let cryptoDetailRepository: CryptoDetailRepository
    private let toplistRepository: ToplistRepository
    private let portfolioRepository: PortfolioRepository
    
    var walletName = ""
    var address = ""
    var selectedChain = Chain.btc
    var isImporting = false
    var showImportError = false
    
    private let chains = Chain.allCases
    
    var chainCoins: [Toplist]?
    
    init(
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        portfolioRepository: PortfolioRepository = PortfolioRepositoryImp.shared
    ) {
        self.cryptoDetailRepository = cryptoDetailRepository
        self.toplistRepository = toplistRepository
        self.portfolioRepository = portfolioRepository
    }
    
    func getToplist() async {
        if let coins = await toplistRepository.getMarketToplist(
            sortOption: .mktCapDesc,
            priceChange: .sevenDays,
            platformId: nil
        ) {
            let chainIds = chains.map { $0.id }
            self.chainCoins = coins.filter { chainIds.contains($0.id ?? "") }
        }
    }

    func importWallet() async -> Bool {
        showImportError = false
        isImporting = true
        
        defer {
            isImporting = false
        }
        
        guard let coinData = await cryptoDetailRepository.getCurrencyDetails(id: selectedChain.id) else {
            showImportError = true
            return false
        }

        await portfolioRepository.ensureCacheLoaded()
        let previousTransactionCount = await portfolioRepository.cachedPortfolioPies?.data.allTransactionsCount ?? 0
        
        let (portfolio, currencies) = await portfolioRepository.importWallet(
            walletName: walletName.isEmpty ? nil : walletName,
            coinData: coinData,
            address: address,
            chain: selectedChain,
            isRefreshing: false
        )
        
        guard portfolio != nil, currencies != nil else {
            showImportError = true
            return false
        }

        AnalyticsManager.shared.log(
            TransactionAdded(
                fromScreen: .newImportTransaction,
                coinName: coinData.name ?? ""
            )
        )

        NotificationCenter.default.post(
            Notification(
                name: .newTransaction,
                object: nil,
                userInfo: [
                    "transaction": address,
                    "previousTransactionCount": previousTransactionCount
                ]
            )
        )
        NotificationCenter.default.post(Notification(name: .showRatingView, object: nil, userInfo: [:]))
        return true
    }
}
