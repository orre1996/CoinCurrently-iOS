//
//  TreasuryDetailRepository.swift
//  CoinCurrently
//

import Foundation

protocol TreasuryDetailRepository: Actor {
    var cachedTreasuryDetails: [String: CachedData<TreasuryDetailEntity>] { get }
    var cachedHoldingCharts: [String: CachedData<TreasuryHoldingChartModel>] { get }
    var cachedTransactionHistory: [String: CachedData<TreasuryTransactionHistoryModel>] { get }

    func ensureCacheLoaded() async
    func loadCachedDataForTreasury(id: String, coinId: String, days: String) async
    func getTreasuryDetail(id: String?) async -> TreasuryDetailEntity?
    func getHoldingChart(id: String?, coinId: String, days: String) async -> TreasuryHoldingChartModel?
    func getTransactionHistory(id: String?, coinId: String?) async -> TreasuryTransactionHistoryModel?
}

final actor TreasuryDetailRepositoryImp: TreasuryDetailRepository {
    static let shared = TreasuryDetailRepositoryImp()

    private let networkManager: NetworkManager

    private(set) var cachedTreasuryDetails: [String: CachedData<TreasuryDetailEntity>] = [:]
    private(set) var cachedHoldingCharts: [String: CachedData<TreasuryHoldingChartModel>] = [:]
    private(set) var cachedTransactionHistory: [String: CachedData<TreasuryTransactionHistoryModel>] = [:]

    private var hasLoadedFromStorage = false

    init(networkManager: NetworkManager = NetworkManagerImp.shared) {
        self.networkManager = networkManager
    }

    func ensureCacheLoaded() async {
        guard !hasLoadedFromStorage else { return }
        hasLoadedFromStorage = true
    }

    func loadCachedDataForTreasury(id: String, coinId: String, days: String) async {
        await ensureCacheLoaded()

        if let detail: TreasuryDetailEntity = await networkManager.getCached(
            endpoint: .treasuryDetail(entityId: id)
        ) {
            cachedTreasuryDetails[id] = CachedData(data: detail.copy(withId: id), date: Date())
        }

        if let chart: TreasuryHoldingChartModel = await networkManager.getCached(
            endpoint: .treasuryHoldingChart(entityId: id, coinId: coinId, days: days)
        ) {
            cachedHoldingCharts[chartCacheKey(id: id, coinId: coinId, days: days)] = CachedData(data: chart, date: Date())
        }

        if let history: TreasuryTransactionHistoryModel = await networkManager.getCached(
            endpoint: .treasuryTransactionHistory(entityId: id, coinIds: coinId)
        ) {
            cachedTransactionHistory[transactionHistoryCacheKey(id: id, coinId: coinId)] = CachedData(data: history, date: Date())
        }
    }

    func getTreasuryDetail(id: String?) async -> TreasuryDetailEntity? {
        await ensureCacheLoaded()
        guard let id else { return nil }

        let detail: TreasuryDetailEntity? = await networkManager.get(
            endpoint: .treasuryDetail(entityId: id)
        )

        if let detail {
            cachedTreasuryDetails[id] = CachedData(data: detail.copy(withId: id), date: Date())
        }

        return detail?.copy(withId: id)
    }

    func getHoldingChart(id: String?, coinId: String, days: String) async -> TreasuryHoldingChartModel? {
        await ensureCacheLoaded()
        guard let id else { return nil }

        let chart: TreasuryHoldingChartModel? = await networkManager.get(
            endpoint: .treasuryHoldingChart(entityId: id, coinId: coinId, days: days)
        )

        if let chart {
            cachedHoldingCharts[chartCacheKey(id: id, coinId: coinId, days: days)] = CachedData(data: chart, date: Date())
        }

        return chart
    }

    func getTransactionHistory(
        id: String?,
        coinId: String?
    ) async -> TreasuryTransactionHistoryModel? {
        await ensureCacheLoaded()
        guard let id else { return nil }

        let history: TreasuryTransactionHistoryModel? = await networkManager.get(
            endpoint: .treasuryTransactionHistory(
                entityId: id,
                coinIds: coinId,
                page: 1,
                perPage: 100
            )
        )

        if let history {
            cachedTransactionHistory[transactionHistoryCacheKey(id: id, coinId: coinId)] = CachedData(data: history, date: Date())
        }

        return history
    }

    private func chartCacheKey(id: String, coinId: String, days: String) -> String {
        "\(id)-\(coinId)-\(days)"
    }

    private func transactionHistoryCacheKey(id: String, coinId: String?) -> String {
        "\(id)-\(coinId ?? "all")"
    }
}
