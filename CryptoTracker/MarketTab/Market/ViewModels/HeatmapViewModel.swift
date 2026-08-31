//
//  HeatmapViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-08-23.
//

import Foundation
import SwiftUI

@MainActor
protocol HeatmapViewModel {
    var toplist: [Toplist] { get }
    var favoritesList: [Toplist] { get }
    var portfolioList: [Toplist] { get }
    var category: CryptoCategory? { get }
    
    func loadHeatmapData() async
}

@MainActor @Observable
final class HeatmapViewModelImp: HeatmapViewModel {
    private(set) var toplist = [Toplist]()
    private(set) var favoritesList = [Toplist]()
    private(set) var portfolioList = [Toplist]()
    private(set) var category: CryptoCategory?
    
    private let toplistRepository: ToplistRepository
    private let portfolioRepository: PortfolioRepository
    
    init(
        category: CryptoCategory? = nil,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        portfolioRepository: PortfolioRepository = PortfolioRepositoryImp.shared
    ) {
        self.category = category
        self.toplistRepository = toplistRepository
        self.portfolioRepository = portfolioRepository
    }
    
    func loadHeatmapData() async {
        await toplistRepository.ensureCacheLoaded()
        await portfolioRepository.ensureCacheLoaded()
        
        if let favorites = await toplistRepository.getFavorites() {
            favoritesList = favorites
        } else if let cachedFavorites = await toplistRepository.cachedFavorites?.data {
            favoritesList = cachedFavorites
        }
        
        let fetchedPortfolio = await portfolioRepository.getPortfolio()
        let portfolioCache: CachedPortfolioPies?
        if let fetchedPortfolio {
            portfolioCache = fetchedPortfolio
        } else {
            portfolioCache = await portfolioRepository.cachedPortfolioPies
        }
        portfolioList = Self.extractPortfolioCoins(from: portfolioCache)
        
        if let toplist = await toplistRepository.getMarketToplist(
            sortOption: .mktCapDesc,
            priceChange: .sevenDays,
            platformId: category?.id
        ) {
            self.toplist = toplist
        }
    }
    
    private static func extractPortfolioCoins(from cached: CachedPortfolioPies?) -> [Toplist] {
        guard let cached else { return [] }
        
        var allPies = cached.data
        for otherCoin in cached.otherCoins where !allPies.contains(where: { $0.data?.id == otherCoin.id }) {
            allPies.append(Pie(data: otherCoin))
        }
        
        return allPies
            .filter { !($0.transactions.isEmpty && $0.swaps.isEmpty && $0.imports.isEmpty) }
            .compactMap(\.data)
            .sorted { ($0.market_cap ?? 0) > ($1.market_cap ?? 0) }
    }
}
