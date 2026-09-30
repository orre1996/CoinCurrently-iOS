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
    func getNews(itemCount: Int, completion: @escaping (Result<NewsEntry, Error>) -> Void)
    func getFearGreed(completion: @escaping (Result<FearGreedEntry, Error>) -> Void)
    func getGasFees(completion: @escaping (Result<GasFeeEntry, Error>) -> Void)
}

final class WidgetViewModelImp: WidgetViewModel, @unchecked Sendable {
    private let networkManager: NetworkManager
    
    private let portfolioRepository: PortfolioRepository
    private let priceAlertsRepository: PriceAlertsRepository
    private let newsRepository: NewsRepository
    private let fearGreedRepository: FearGreedRepository
    private let gasFeesRepository: GasFeesRepository
    
    init(
        networkManager: NetworkManager = NetworkManagerImp.shared,
        portfolioRepository: PortfolioRepository = PortfolioRepositoryImp.shared,
        priceAlertsRepository: PriceAlertsRepository = PriceAlertsRepositoryImp.shared,
        newsRepository: NewsRepository = NewsRepositoryImp.shared,
        fearGreedRepository: FearGreedRepository = FearGreedRepositoryImp.shared,
        gasFeesRepository: GasFeesRepository = GasFeesRepositoryImp.shared
    ) {
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
        let priceAlerts = priceAlertsRepository
        let net = networkManager
        Task { @MainActor in
            guard let currencies = await priceAlerts.downloadRemainingCoins(ids: ids, withSparkline: true) else {
                box.call(.failure(WidgetError.fail))
                return
            }
            
            let imageDict = await fetchImages(for: currencies.compactMap({ $0.image }), networkManager: net)
            let orderedCurrencies = ids.compactMap { id in
                currencies.first(where: { $0.id == id })
            }
            let displayCurrencies = orderedCurrencies.isEmpty ? currencies : orderedCurrencies
            let displayImages = displayCurrencies.map { entry in
                if let url = entry.image, let image = imageDict[url] {
                    return image
                } else {
                    return UIImage()
                }
            }
            
            box.call(
                .success(
                    CryptoEntry(
                        cryptoInfos: displayCurrencies,
                        currencyLogos: displayImages,
                        selectedCurrency: SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel(),
                        selectedCoinIDs: displayCurrencies.compactMap(\.id),
                        isPlaceholder: false
                    )
                )
            )
        }
    }
    
    func getPortfolio(completion: @escaping (Result<PortfolioEntry, Error>) -> Void) {
        let box = CompletionBox(handler: completion)
        let portfolio = portfolioRepository
        Task { @MainActor in
            guard let pieModel = await portfolio.getPortfolio() else {
                box.call(.failure(WidgetError.fail))
                return
            }
             
            guard let allPrices = await portfolio.getPortfolioAllCurrencies() else {
                box.call(.failure(WidgetError.fail))
                return
            }
            
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
                        isPlaceholder: false
                    )
                )
            )
        }
    }

    // MARK: - News
    
    func getNews(itemCount: Int = 3, completion: @escaping (Result<NewsEntry, Error>) -> Void) {
        let box = CompletionBox(handler: completion)
        let newsRepo = newsRepository
        Task { @MainActor in
            guard let news = await newsRepo.getNews(coinId: nil) else {
                box.call(.failure(WidgetError.fail))
                return
            }

            let items = Array(news.prefix(itemCount))

            guard !items.isEmpty else {
                box.call(.failure(WidgetError.fail))
                return
            }
            
            box.call(
                .success(
                    NewsEntry(
                        newsModel: items,
                        isPlaceholder: false
                    )
                )
            )
        }
    }
    
    // MARK: - Fear and Greed
    
    func getFearGreed(completion: @escaping (Result<FearGreedEntry, Error>) -> Void) {
        let box = CompletionBox(handler: completion)
        let fearGreed = fearGreedRepository
        Task { @MainActor in
            guard let fearGreedModel = await fearGreed.getFearGreed() else {
                box.call(.failure(WidgetError.fail))
                return
            }
            
            box.call(
                .success(
                    FearGreedEntry(
                        fearModel: fearGreedModel,
                        isPlaceholder: false
                    )
                )
            )
        }
    }

    // MARK: - Gas fees
    
    func getGasFees(completion: @escaping (Result<GasFeeEntry, Error>) -> Void) {
        let box = CompletionBox(handler: completion)
        let gasFees = gasFeesRepository
        Task { @MainActor in
            guard let gasFeesModel = await gasFees.getGasFees() else {
                box.call(.failure(WidgetError.fail))
                return
            }
            
            box.call(
                .success(
                    GasFeeEntry(
                        gasFeesModel: gasFeesModel,
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
        let ids = await WidgetCoinStorage.snapshotCoinIDs()
        guard !ids.isEmpty,
              let currencies = await priceAlertsRepository.downloadRemainingCoins(ids: ids, withSparkline: true) else {
            return
        }
        await CoinImageCache.prefetch(urlStrings: currencies.compactMap(\.image))
    }

    func fetchSnapshotEntry(limit: Int = 8) async -> CryptoEntry {
        let ids = await WidgetCoinStorage.snapshotCoinIDs(limit: limit)
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
