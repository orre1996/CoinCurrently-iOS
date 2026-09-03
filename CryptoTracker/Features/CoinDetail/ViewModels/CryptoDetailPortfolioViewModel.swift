//
//  CryptoDetailPortfolioViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/2/26.
//

import Foundation

@MainActor
@Observable
final class CryptoDetailPortfolioViewModel {
    var pie: Pie?
    var portfolio: [Pie]?
    var allPrices = [Cryptocurrency]()
    var hidePortfolioData: Bool
    var groupedTransactions: [Date: [any PortfolioEvent]]?

    private var coinId: String?

    private let portfolioRepository: PortfolioRepository
    private let storeKitManager: StoreKitManager
    private let settingsManager: SettingsManager

    init(
        portfolioRepository: PortfolioRepository = PortfolioRepositoryImp.shared,
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared,
        settingsManager: SettingsManager = SettingsManager.shared
    ) {
        self.portfolioRepository = portfolioRepository
        self.storeKitManager = storeKitManager
        self.settingsManager = settingsManager
        self.hidePortfolioData = settingsManager.get(key: AppSettingKey.hidePortfolioValues) ?? false
    }

    func reset() {
        coinId = nil
        pie = nil
        groupedTransactions = nil
    }

    func load(coinId: String?) async {
        if self.coinId != coinId {
            pie = nil
            groupedTransactions = nil
        }
        self.coinId = coinId

        async let portfolioTask = portfolioRepository.getPortfolio()
        async let currenciesTask = portfolioRepository.getPortfolioAllCurrencies()

        let fetchedPortfolio = await portfolioTask
        let allCurrencies = await currenciesTask

        portfolio = fetchedPortfolio?.data
        allPrices = allCurrencies ?? []
        pie = portfolio?.first(where: { $0.data?.id == coinId })
        setGroupTransactions()
    }

    func setGroupTransactions() {
        guard let portfolio else {
            groupedTransactions = [:]
            return
        }

        let coinSlices = portfolio.filter({ $0.data?.id == coinId }).compactMap({ $0.data })
        var result = coinSlices.isEmpty ? [:] : portfolio.groupedTransactions(
            types: [],
            on: .all,
            coinNames: coinSlices
        )

        if let targetId = coinId {
            let calendar = Calendar.current
            var seenIds = Set(result.values.flatMap { $0.map(\.id) })

            for swap in portfolio.flatMap({ $0.swaps }).filter({ $0.fromCurrencyId == targetId }) {
                guard !seenIds.contains(swap.id) else { continue }
                seenIds.insert(swap.id)
                let day = calendar.startOfDay(for: swap.date)
                result[day, default: []].append(swap)
            }

            for key in result.keys {
                result[key]?.sort { $0.date > $1.date }
            }
        }

        groupedTransactions = result
    }

    func deleteTransaction(_ transaction: (any PortfolioEvent)?) async {
        guard let transaction else {
            return
        }

        let id = portfolio?.pie(containing: transaction)?.data?.id ?? ""

        portfolio = await portfolioRepository.deleteTransaction(
            id: id,
            uuid: transaction.id
        )?.data

        pie = portfolio?.first(where: { $0.data?.id == coinId })
        setGroupTransactions()
    }

    func findTransaction(transaction: String) async -> ((any PortfolioEvent)?, Toplist?) {
        await portfolioRepository.findTransaction(lookup: transaction)
    }

    func hasBoughtPro() async -> Bool {
        await storeKitManager.currentSubscription != nil
    }

    func toggleHideData() {
        hidePortfolioData.toggle()
        settingsManager.set(data: hidePortfolioData, key: AppSettingKey.hidePortfolioValues)
    }
}
