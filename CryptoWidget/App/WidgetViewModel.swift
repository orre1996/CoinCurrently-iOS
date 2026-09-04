//
//  WidgetViewModel.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-27.
//

import Foundation
import SwiftUI

private final class CompletionBox<T>: @unchecked Sendable {
    let handler: (T) -> Void
    init(handler: @escaping (T) -> Void) { self.handler = handler }
    func call(_ value: T) { handler(value) }
}

enum WidgetError: Error {
    case fail
}

protocol WidgetViewModel {
    func getCoinsWithSparkline(ids: [String], completion: @escaping (Result<CryptoEntry, Error>) -> Void)
    func getPortfolio(completion: @escaping (Result<PortfolioEntry, Error>) -> Void)
    func getNews(type: NewsType, category: NewsWidgetCategory, itemCount: Int, completion: @escaping (Result<NewsEntry, Error>) -> Void)
    func getFearGreed(completion: @escaping (Result<FearGreedEntry, Error>) -> Void)
    func getGasFees(completion: @escaping (Result<GasFeeEntry, Error>) -> Void)
}

final class WidgetViewModelImp: WidgetViewModel, @unchecked Sendable {
    private let storeKitManager: StoreKitManager
    private let networkManager: NetworkManager
    
    private let portfolioRepository: PortfolioRepository
    private let priceAlertsRepository: PriceAlertsRepository
    private let newsRepository: NewsRepository
    private let fearGreedRepository: FearGreedRepository
    private let gasFeesRepository: GasFeesRepository
    
    init(
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared,
        networkManager: NetworkManager = NetworkManagerImp.shared,
        portfolioRepository: PortfolioRepository = PortfolioRepositoryImp.shared,
        priceAlertsRepository: PriceAlertsRepository = PriceAlertsRepositoryImp.shared,
        newsRepository: NewsRepository = NewsRepositoryImp.shared,
        fearGreedRepository: FearGreedRepository = FearGreedRepositoryImp.shared,
        gasFeesRepository: GasFeesRepository = GasFeesRepositoryImp.shared
    ) {
        self.storeKitManager = storeKitManager
        self.networkManager = networkManager
        self.portfolioRepository = portfolioRepository
        self.priceAlertsRepository = priceAlertsRepository
        self.newsRepository = newsRepository
        self.fearGreedRepository = fearGreedRepository
        self.gasFeesRepository = gasFeesRepository
        
        Task {
            await self.networkManager.setCurrentScreen("General")
        }
    }

    func getCoinsWithSparkline(ids: [String], completion: @escaping (Result<CryptoEntry, Error>) -> Void) {
        let box = CompletionBox(handler: completion)
        let storeKit = storeKitManager
        let priceAlerts = priceAlertsRepository
        let net = networkManager
        Task { @MainActor in
            await storeKit.setStartData(downloadSubscriptions: false)
            
            guard let currencies = await priceAlerts.downloadRemainingCoins(ids: ids, withSparkline: true) else {
                box.call(.failure(WidgetError.fail))
                return
            }
            
            let imageDict = await fetchImages(for: currencies.compactMap({ $0.image }), networkManager: net)

            let images = currencies.map { entry in
                if let url = entry.image, let image = imageDict[url] {
                    return image
                } else {
                    return UIImage()
                }
            }
            
            let hasPro = await storeKit.currentSubscription != nil
            
            box.call(
                .success(
                    CryptoEntry(
                        cryptoInfos: currencies,
                        currencyLogos: images,
                        selectedCurrency: SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel(),
                        selectedCoinIDs: ids,
                        hasPro: hasPro,
                        isPlaceholder: false
                    )
                )
            )
        }
    }
    
    func getPortfolio(completion: @escaping (Result<PortfolioEntry, Error>) -> Void) {
        let box = CompletionBox(handler: completion)
        let storeKit = storeKitManager
        let portfolio = portfolioRepository
        Task { @MainActor in
            await storeKit.setStartData(downloadSubscriptions: false)
            
            guard let pieModel = await portfolio.getPortfolio() else {
                box.call(.failure(WidgetError.fail))
                return
            }
             
            guard let allPrices = await portfolio.getPortfolioAllCurrencies() else {
                box.call(.failure(WidgetError.fail))
                return
            }
            
            let hasPro = await storeKit.currentSubscription != nil
            let selectedCurrency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
            let portfolioData = pieModel.data
            let totalValue = Self.calculateTotalValue(
                portfolio: portfolioData,
                allPrices: allPrices,
                currencyCode: selectedCurrency.code
            )
            let profitLossValue = portfolioData.getProfitLossValue(
                coinPrices: allPrices,
                showCurrency: selectedCurrency.code
            )
            let profitLossPercent = portfolioData.getProfitLossPercent(
                coinPrices: allPrices,
                showCurrency: selectedCurrency.code
            )
            
            await CoinImageCache.prefetch(urlStrings: portfolioData.compactMap { $0.data?.image })
            
            box.call(
                .success(
                    PortfolioEntry(
                        pieModel: portfolioData,
                        allPrices: allPrices,
                        selectedCurrency: selectedCurrency,
                        totalValue: totalValue,
                        profitLossValue: profitLossValue,
                        profitLossPercent: profitLossPercent,
                        hasPro: hasPro,
                        isPlaceholder: false
                    )
                )
            )
        }
    }

    // MARK: - News
    
    func getNews(type: NewsType, category: NewsWidgetCategory = .general, itemCount: Int = 3, completion: @escaping (Result<NewsEntry, Error>) -> Void) {
        let box = CompletionBox(handler: completion)
        let storeKit = storeKitManager
        let newsRepo = newsRepository
        Task { @MainActor in
            await storeKit.setStartData(downloadSubscriptions: false)

            let fetchCount = NewsWidgetCategoryResolver.fetchCount(for: type, itemCount: itemCount)

            guard var news = await newsRepo.getNews(type: type, count: fetchCount) else {
                box.call(.failure(WidgetError.fail))
                return
            }

            news = Array(NewsWidgetCategoryResolver.filteredNews(news, for: type).prefix(itemCount))

            guard !news.isEmpty else {
                box.call(.failure(WidgetError.fail))
                return
            }
            
            let hasPro = await storeKit.currentSubscription != nil
            
            box.call(
                .success(
                    NewsEntry(
                        newsModel: news,
                        hasPro: hasPro,
                        selectedCategory: category,
                        isPlaceholder: false
                    )
                )
            )
        }
    }
    
    // MARK: - Fear and Greed
    
    func getFearGreed(completion: @escaping (Result<FearGreedEntry, Error>) -> Void) {
        let box = CompletionBox(handler: completion)
        let storeKit = storeKitManager
        let fearGreed = fearGreedRepository
        Task { @MainActor in
            await storeKit.setStartData(downloadSubscriptions: false)
            
            guard let fearGreedModel = await fearGreed.getFearGreed() else {
                box.call(.failure(WidgetError.fail))
                return
            }
            
            let hasPro = await storeKit.currentSubscription != nil
            
            box.call(
                .success(
                    FearGreedEntry(
                        fearModel: fearGreedModel,
                        hasPro: hasPro,
                        isPlaceholder: false
                    )
                )
            )
        }
    }

    // MARK: - Gas fees
    
    func getGasFees(completion: @escaping (Result<GasFeeEntry, Error>) -> Void) {
        let box = CompletionBox(handler: completion)
        let storeKit = storeKitManager
        let gasFees = gasFeesRepository
        Task { @MainActor in
            await storeKit.setStartData(downloadSubscriptions: false)
            
            guard let gasFeesModel = await gasFees.getGasFees() else {
                box.call(.failure(WidgetError.fail))
                return
            }
            
            let hasPro = await storeKit.currentSubscription != nil
            
            box.call(
                .success(
                    GasFeeEntry(
                        gasFeesModel: gasFeesModel,
                        hasPro: hasPro,
                        isPlaceholder: false
                    )
                )
            )
        }
    }
    
    // MARK: - Helper functions

    private static func calculateTotalValue(
        portfolio: [Pie],
        allPrices: [Cryptocurrency],
        currencyCode: String
    ) -> Double? {
        let pricesById = Dictionary(uniqueKeysWithValues: allPrices.map { ($0.id, $0.prices) })
        let code = currencyCode.lowercased()

        return portfolio.reduce(0.0) { sum, pie in
            guard let id = pie.data?.id else { return sum }
            let lastPrice = pie.data?.holdingPrice(
                vsCurrencyPrices: pricesById[id],
                currencyCode: code
            ) ?? 0
            let amount = portfolio.getAllTransactions(of: id).getAmount()
            return sum + lastPrice * amount
        }
    }

    private func fetchImages(for imageUrls: [String], networkManager: NetworkManager) async -> [String: UIImage] {
        var result = [String: UIImage]()

        await withTaskGroup(of: (String, UIImage).self) { group in
            for url in imageUrls {
                group.addTask {
                    guard let data: Data = await networkManager.get(endpoint: .image(url: url)), let image = UIImage(data: data) else {
                        return (url, UIImage())
                    }

                    return (url, image)
                }
            }

            for await (url, image) in group {
                result[url] = image
            }
        }

        return result
    }

    @MainActor
    func prefetchSnapshotCoins() async {
        await storeKitManager.setStartData(downloadSubscriptions: false)
        let ids = await WidgetCoinStorage.snapshotCoinIDs()
        guard !ids.isEmpty,
              let currencies = await priceAlertsRepository.downloadRemainingCoins(ids: ids, withSparkline: true) else {
            return
        }
        await CoinImageCache.prefetch(urlStrings: currencies.compactMap(\.image))
    }

    func fetchSnapshotEntry() async -> CryptoEntry {
        let ids = await WidgetCoinStorage.snapshotCoinIDs()
        let entry = await fetchDisplayEntry(ids: ids)
        return entry.selectedCoinIDs.isEmpty ? entry : entry.copyWithPlaceholder()
    }

    func fetchDisplayEntry(ids: [String]) async -> CryptoEntry {
        guard !ids.isEmpty else {
            return CryptoEntry.empty()
        }

        return await withCheckedContinuation { continuation in
            getCoinsWithSparkline(ids: ids) { result in
                switch result {
                case .success(let entry):
                    continuation.resume(returning: entry)
                case .failure:
                    continuation.resume(returning: CryptoEntry.empty(selectedCoinIDs: ids))
                }
            }
        }
    }
}
