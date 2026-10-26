//
//  GlobalMarketRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-12.
//

import Foundation
import Combine
import SwiftUI

protocol GlobalMarketRepository: Actor {
    var cachedGlobalMarket: CachedData<GlobalMarketModel?>? { get }
    var cachedGlobalChart: CachedData<GlobalMarketChartModel?>? { get }
    var cachedCoinList: CachedData<[CoinsListModel]>? { get }
    
    func ensureCacheLoaded() async
    func getAllCoins() async -> [CoinsListModel]?
    func getGlobalMarket() async -> GlobalMarketModel?
    func getGlobalChart(days: String) async -> GlobalMarketChartData?
    func getColors() async -> AsyncStream<GlobalMarketModel?>
}

final actor GlobalMarketRepositoryImp: GlobalMarketRepository {
    static let shared = GlobalMarketRepositoryImp()

    var cachedGlobalMarket: CachedData<GlobalMarketModel?>?
    var cachedGlobalChart: CachedData<GlobalMarketChartModel?>?
    var cachedCoinList: CachedData<[CoinsListModel]>?

    private let networkManager: NetworkManager
    
    private let invalidIds = ["binance-", "bridged-", "harry", "mapped", "bridge-", "batcat", "nova", "osmosis-", "department", "open-", "tokamak-", "big-"]
    
    init(
        networkManager: NetworkManager = NetworkManagerImp.shared
    ) {
        self.networkManager = networkManager
        
        self.cachedGlobalMarket = nil
        self.cachedGlobalChart = nil
        self.cachedCoinList = nil

        Task {
            await ensureCacheLoaded()
            _ = await getAllCoins()
        }
    }
    
    private var hasLoadedFromStorage = false
    
    func ensureCacheLoaded() async {
        guard !hasLoadedFromStorage else { return }
        hasLoadedFromStorage = true
        
        if let global: GlobalMarketModel = await networkManager.getCached(endpoint: .global) {
            cachedGlobalMarket = CachedData(data: global, date: Date())
        }
        
        if let coins: [CoinsListModel] = await networkManager.getCached(endpoint: .allCoins) {
            cachedCoinList = CachedData(data: coins, date: Date())
        }
        
        let cachedChartDays = TimeCharts.getStartTimeFrame(between: .aWeek, and: .max).days
        if let globalChart: GlobalMarketChartModel = await networkManager.getCached(
            endpoint: .globalChart(days: cachedChartDays)
        ) {
            let filteredChart = filterGlobalChart(globalChart, days: cachedChartDays) ?? globalChart
            cachedGlobalChart = CachedData(data: filteredChart, date: Date())
        }
    }

    func getAllCoins() async -> [CoinsListModel]? {
        await ensureCacheLoaded()
        
        let coinsList: [CoinsListModel]? = await networkManager.get(endpoint: .allCoins)

        if let coinsList {
            cachedCoinList = CachedData(data: coinsList, date: Date())
        }

        return coinsList
    }
    
    func getGlobalChart(days: String) async -> GlobalMarketChartData? {
        await ensureCacheLoaded()
        let globalChart: GlobalMarketChartModel? = await networkManager.get(endpoint: .globalChart(days: days))
        let filteredChart = filterGlobalChart(globalChart, days: days)

        if let filteredChart {
            cachedGlobalChart = CachedData(data: filteredChart, date: Date())
        }

        return filteredChart?.market_cap_chart
    }
    
    func getGlobalMarket() async -> GlobalMarketModel? {
        await ensureCacheLoaded()
        
        var globalMarket: GlobalMarketModel? = await networkManager.get(endpoint: .global)

        if var tempMarket = globalMarket, let cachedPercentages = cachedGlobalMarket?.data?.data?.percentages {
            cachedPercentages.enumerated().forEach { index, data in
                tempMarket.data?.percentages?[index].color = data.color
                tempMarket.data?.percentages?[index].image = data.image
            }

            globalMarket = tempMarket
        }
        
        cachedGlobalMarket = CachedData(data: globalMarket, date: Date())

        return globalMarket
    }

    func getColors() -> AsyncStream<GlobalMarketModel?> {
        return AsyncStream { continuation in
            guard let cachedCoinList, !cachedCoinList.data.isEmpty,
                  var globalMarket = cachedGlobalMarket?.data,
                  let percentages = cachedGlobalMarket?.data?.data?.percentages, !percentages.isEmpty else {
                continuation.yield(nil)
                return
            }
            
            let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
            let validCoinIds = getValidCoinIds(coins: cachedCoinList.data)
            
            Task {
                guard !validCoinIds.isEmpty, let coins: [Toplist] = await networkManager.get(
                    endpoint: .multipleCoins(
                        ids: validCoinIds,
                        currency: currency
                    )
                ) else {
                    continuation.yield(nil)
                    return
                }
                
                await withTaskGroup(of: (String, Data?).self) { taskGroup in
                    for coin in coins {
                        guard let coinImage = coin.image, let symbol = coin.symbol else {
                            continue
                        }
                        
                        taskGroup.addTask { (symbol, await self.networkManager.get(endpoint: .image(url: coinImage))) }
                    }
                    
                    for await data in taskGroup where data.1 != nil {
                        let symbol = data.0
                        let imageData = data.1
                        
                        if let data = imageData, let image = UIImage(data: data) {
                            let color = Color(image.getColors(quality: .high).background).hexStringFromColor()
                            
                            if let index = globalMarket.data?.percentages?.firstIndex(where: { $0.symbol == symbol }) {
                                globalMarket.data?.percentages?[index].color = color
                                globalMarket.data?.percentages?[index].image = data.base64EncodedString()
                                
                                continuation.yield(globalMarket)
                            }
                        }
                    }
                }
                
                let cacheDate = cachedGlobalMarket?.date ?? Date()
                cachedGlobalMarket = CachedData(data: globalMarket, date: cacheDate)
                await networkManager.persistDecodedResponse(globalMarket, endpoint: .global)
                continuation.finish()
            }
        }
    }

    private func getValidCoinIds(coins: [CoinsListModel]) -> [String] {
        let validCoins = cachedGlobalMarket?.data?.data?.percentages?.filter({ $0.symbol != "OTHER" })

        return validCoins?.compactMap({ coin in
            return coins.filter({ $0.symbol == coin.symbol }).first(where: { isValidId($0.id )} )?.id
        }) ?? []
    }
    
    private func isValidId(_ id: String?) -> Bool {
        return !invalidIds.contains { id?.containsCaseInsensitive(string: $0) ?? false }
    }
    
    private func filterGlobalChart(_ chart: GlobalMarketChartModel?, days: String) -> GlobalMarketChartModel? {
        guard let chart, let chartData = chart.market_cap_chart else { return chart }
        
        let divider = days == "max" ? max(1, (chartData.market_cap?.count ?? 0) / 400) : 1
        
        let filteredData = GlobalMarketChartData(
            market_cap: filterDataPoints(
                chartData.market_cap,
                maxElement: chartData.market_cap?.compactMap({ $0.last ?? 0 }).max() ?? 0,
                minElement: chartData.market_cap?.compactMap({ $0.last ?? 0 }).min() ?? 0,
                divider: divider
            ),
            volume: filterDataPoints(
                chartData.volume,
                maxElement: chartData.volume?.compactMap({ $0.last ?? 0 }).max() ?? 0,
                minElement: chartData.volume?.compactMap({ $0.last ?? 0 }).min() ?? 0,
                divider: divider
            )
        )
        
        return GlobalMarketChartModel(market_cap_chart: filteredData)
    }
    
    private func filterDataPoints(
        _ dataPoints: [[Double?]]?,
        maxElement: Double,
        minElement: Double,
        divider: Int
    ) -> [[Double?]]? {
        let divider = max(1, divider)
        return dataPoints?.enumerated().compactMap { index, element in
            index % divider == 0 || element.last == maxElement || element.last == minElement ? element : nil
        }
    }
}
