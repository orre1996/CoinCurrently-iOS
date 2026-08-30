//
//  AchievementManager.swift
//  CoinCurrently
//

import Foundation

@MainActor
final class AchievementManager {
    static let shared = AchievementManager()

    private(set) var cachedProgress: [AchievementProgress] = []
    private(set) var cachedSummary = AchievementsSummary(
        unlockedLevels: 0,
        totalLevels: 0,
        currentStreak: 0,
        longestStreak: 0
    )

    private var isCheckingUnlocks = false
    private var pendingRecheck = false
    private var progressTask: Task<[AchievementProgress], Never>?

    private let settingsManager: SettingsManager
    private let toplistRepository: ToplistRepository
    private let portfolioRepository: PortfolioRepository
    private let priceAlertsRepository: PriceAlertsRepository
    private let cryptoDetailRepository: CryptoDetailRepository

    init(
        settingsManager: SettingsManager = .shared,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        portfolioRepository: PortfolioRepository = PortfolioRepositoryImp.shared,
        priceAlertsRepository: PriceAlertsRepository = PriceAlertsRepositoryImp.shared,
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared
    ) {
        self.settingsManager = settingsManager
        self.toplistRepository = toplistRepository
        self.portfolioRepository = portfolioRepository
        self.priceAlertsRepository = priceAlertsRepository
        self.cryptoDetailRepository = cryptoDetailRepository
    }

    func increment(_ key: AchievementCounterKey) {
        var counters = loadCounters()
        let previousValue = Double(counters.value(for: key))
        counters.increment(key)
        let newValue = Double(counters.value(for: key))
        saveCounters(counters)

        Task { @MainActor in
            await ensureSnapshotInitializedIfNeeded()
            detectAndDeliverUnlocks(
                for: key.metric,
                previousValue: previousValue,
                newValue: newValue
            )
        }
    }

    func checkForNewUnlocks() async {
        if isCheckingUnlocks {
            pendingRecheck = true
            return
        }

        isCheckingUnlocks = true
        defer {
            isCheckingUnlocks = false
            if pendingRecheck {
                pendingRecheck = false
                Task { @MainActor in
                    await checkForNewUnlocks()
                }
            }
        }

        await ensureSnapshotInitializedIfNeeded()
        invalidateProgressCache()

        let progress = await computeAllProgress()
        var snapshot = loadUnlockSnapshot()
        var newUnlocks: [AchievementUnlockEvent] = []

        for item in progress {
            let previousIndex = snapshot[item.definition.id] ?? -1
            let currentIndex = item.unlockedLevelIndex

            if currentIndex > previousIndex {
                for index in (previousIndex + 1)...currentIndex {
                    let level = item.definition.levels[index]
                    newUnlocks.append(
                        AchievementUnlockEvent(
                            achievementTitle: item.definition.title,
                            levelName: level.name
                        )
                    )
                }
            }

            snapshot[item.definition.id] = max(snapshot[item.definition.id] ?? -1, currentIndex)
        }

        saveUnlockSnapshot(snapshot)
        deliverUnlocks(newUnlocks)
    }

    func checkMetricUnlock(
        for metric: AchievementMetric,
        previousValue: Double,
        newValue: Double
    ) async {
        await ensureSnapshotInitializedIfNeeded()
        invalidateProgressCache()
        detectAndDeliverUnlocks(
            for: metric,
            previousValue: previousValue,
            newValue: newValue
        )
    }

    func checkPortfolioTransactionUnlock(previousCount: Int) async {
        await portfolioRepository.ensureCacheLoaded()
        let newCount = await portfolioRepository.cachedPortfolioPies?.data.allTransactionsCount ?? 0
        await checkMetricUnlock(
            for: .portfolioTransactions,
            previousValue: Double(previousCount),
            newValue: Double(newCount)
        )
    }

    func metricValue(for metric: AchievementMetric) async -> Double {
        invalidateProgressCache()
        let values = await fetchMetricValues()
        return values[metric] ?? 0
    }

    func checkMetricChange(for metric: AchievementMetric, previousValue: Double) async {
        let newValue = await metricValue(for: metric)
        guard newValue != previousValue else { return }
        await checkMetricUnlock(for: metric, previousValue: previousValue, newValue: newValue)
    }

    func currentMaxPortfolioGainPercent() async -> Double {
        await portfolioRepository.ensureCacheLoaded()
        return await maxPortfolioGainPercent()
    }

    func checkMoonShotUnlock(previousMaxGain: Double) async {
        let newMaxGain = await currentMaxPortfolioGainPercent()
        guard newMaxGain != previousMaxGain else { return }
        await checkMetricUnlock(
            for: .maxPortfolioGainPercent,
            previousValue: previousMaxGain,
            newValue: newMaxGain
        )
    }

    func preloadProgress() {
        guard progressTask == nil else { return }

        Task { @MainActor in
            _ = await computeAllProgress()
        }
    }

    func computeAllProgress() async -> [AchievementProgress] {
        if let progressTask {
            return await progressTask.value
        }

        let task = Task { @MainActor in
            await toplistRepository.ensureCacheLoaded()
            await portfolioRepository.ensureCacheLoaded()
            await priceAlertsRepository.ensureCacheLoaded()
            await cryptoDetailRepository.ensureCacheLoaded()

            let metricValues = await fetchMetricValues()
            let snapshot = loadUnlockSnapshot()
            let progress = AchievementCatalog.all.map { definition in
                let currentValue = metricValues[definition.metric] ?? 0
                let computedIndex = definition.levels.lastIndex(where: { currentValue >= $0.threshold }) ?? -1
                let snapshotIndex = snapshot[definition.id] ?? -1
                let unlockedIndex = max(computedIndex, snapshotIndex)
                return AchievementProgress(
                    definition: definition,
                    currentValue: currentValue,
                    unlockedLevelIndex: unlockedIndex
                )
            }
            updateCachedProgress(progress)
            return progress
        }

        progressTask = task
        let progress = await task.value
        progressTask = nil
        return progress
    }

    private func updateCachedProgress(_ progress: [AchievementProgress]) {
        cachedProgress = progress
        cachedSummary = computeSummary(from: progress)
    }

    private func invalidateProgressCache() {
        progressTask = nil
    }

    func computeSummary(from progress: [AchievementProgress]) -> AchievementsSummary {
        let unlockedLevels = progress.reduce(0) { partial, item in
            partial + max(0, item.unlockedLevelIndex + 1)
        }
        let totalLevels = AchievementCatalog.all.reduce(0) { $0 + $1.levels.count }
        return AchievementsSummary(
            unlockedLevels: unlockedLevels,
            totalLevels: totalLevels,
            currentStreak: AchievementStreakTracker.currentStreak,
            longestStreak: AchievementStreakTracker.longestStreak
        )
    }

    private func ensureSnapshotInitializedIfNeeded() async {
        let isInitialized: Bool = settingsManager.get(key: AppSettingKey.achievementUnlockSnapshotInitialized) ?? false
        guard !isInitialized else { return }

        let progress = await computeAllProgress()
        var snapshot: [String: Int] = [:]
        for item in progress {
            snapshot[item.definition.id] = item.unlockedLevelIndex
        }
        saveUnlockSnapshot(snapshot)
        settingsManager.set(data: true, key: AppSettingKey.achievementUnlockSnapshotInitialized)
    }

    private func detectAndDeliverUnlocks(
        for metric: AchievementMetric,
        previousValue: Double,
        newValue: Double
    ) {
        let definitions = AchievementCatalog.all.filter { $0.metric == metric }
        guard !definitions.isEmpty else { return }

        var snapshot = loadUnlockSnapshot()
        var newUnlocks: [AchievementUnlockEvent] = []

        for definition in definitions {
            let previousIndex = definition.levels.lastIndex(where: { previousValue >= $0.threshold }) ?? -1
            let currentIndex = definition.levels.lastIndex(where: { newValue >= $0.threshold }) ?? -1
            let snapshotIndex = snapshot[definition.id] ?? -1
            let firstNewIndex = max(previousIndex, snapshotIndex) + 1

            if currentIndex >= firstNewIndex {
                for index in firstNewIndex...currentIndex {
                    let level = definition.levels[index]
                    newUnlocks.append(
                        AchievementUnlockEvent(
                            achievementTitle: definition.title,
                            levelName: level.name
                        )
                    )
                }
            }

            snapshot[definition.id] = max(snapshot[definition.id] ?? -1, currentIndex)
        }

        saveUnlockSnapshot(snapshot)
        deliverUnlocks(newUnlocks)
    }

    private func loadCounters() -> AchievementCounters {
        settingsManager.get(key: AppSettingKey.achievementCounters) ?? AchievementCounters()
    }

    private func saveCounters(_ counters: AchievementCounters) {
        settingsManager.set(data: counters, key: AppSettingKey.achievementCounters)
    }

    private func loadUnlockSnapshot() -> [String: Int] {
        settingsManager.get(key: AppSettingKey.achievementUnlockSnapshot) ?? [:]
    }

    private func saveUnlockSnapshot(_ snapshot: [String: Int]) {
        settingsManager.set(data: snapshot, key: AppSettingKey.achievementUnlockSnapshot)
    }

    private func deliverUnlocks(_ unlocks: [AchievementUnlockEvent]) {
        guard !unlocks.isEmpty else { return }

        for unlock in unlocks {
            deliverUnlock(unlock)
        }
    }

    private func deliverUnlock(_ unlock: AchievementUnlockEvent) {
#if IS_APP
        asyncMain {
            AchievementNavigationManager.showUnlock(unlock)
        }
#endif
    }

    private func uniqueSearchCount() -> Double {
        let history: [String: [SearchResult]] = settingsManager.get(key: AppSettingKey.searchHistory) ?? [:]
        return Double(Set(history.values.flatMap { $0.compactMap(\.id) }).count)
    }

    private func maxPortfolioGainPercent() async -> Double {
        let portfolio = await portfolioRepository.cachedPortfolioPies?.data ?? []
        let prices = await portfolioRepository.cachedPortfolioPrices?.data ?? []
        let currency: CurrencyModel = settingsManager.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        let showCurrency = currency.code

        var maxGain: Double = 0
        for pie in portfolio {
            guard let coinId = pie.data?.id else { continue }
            let transactions = portfolio.getAllTransactions(of: coinId)
            let coinPrices = prices.first(where: { $0.id == coinId })?.prices
            guard let gain = transactions.getProfitPercent(prices: coinPrices, showCurrency: showCurrency),
                  gain.isFinite else { continue }
            maxGain = max(maxGain, gain)
        }
        return max(0, maxGain)
    }

    private func fetchMetricValues() async -> [AchievementMetric: Double] {
        let counters = loadCounters()
        let favoritesCount = Double(await toplistRepository.cachedFavorites?.data.count ?? 0)
        let transactionCount = Double(await portfolioRepository.cachedPortfolioPies?.data.allTransactionsCount ?? 0)
        let alertsCount = Double(await priceAlertsRepository.cachedPriceAlerts?.data.count ?? 0)
        let widgetCount = Double(await cryptoDetailRepository.widgetCurrencies.count)
        let authEnabled: Bool = settingsManager.get(key: AppSettingKey.authenticationEnabled) ?? false
        let referralCount = Double(await ReferralRepositoryImp.shared.cachedUser?.data.referralCount ?? counters.referralsCompleted)

        return [
            .dailyStreak: Double(AchievementStreakTracker.currentStreak),
            .favoritesCount: favoritesCount,
            .portfolioTransactions: transactionCount,
            .maxPortfolioGainPercent: await maxPortfolioGainPercent(),
            .priceAlertsCount: alertsCount,
            .widgetCoinsCount: widgetCount,
            .uniqueSearches: uniqueSearchCount(),
            .cryptoDetailsViewed: Double(counters.cryptoDetailsViewed),
            .compareSessions: Double(counters.compareSessions),
            .newsArticlesOpened: Double(counters.newsArticlesOpened),
            .nftDetailsViewed: Double(counters.nftDetailsViewed),
            .exchangeDetailsViewed: Double(counters.exchangeDetailsViewed),
            .sectorDetailsViewed: Double(counters.sectorDetailsViewed),
            .fearGreedVisits: Double(counters.fearGreedVisits),
            .gasFeesVisits: Double(counters.gasFeesVisits),
            .treasuryVisits: Double(counters.treasuryVisits),
            .candleChartToggles: Double(counters.candleChartToggles),
            .converterUses: Double(counters.converterUses),
            .portfolioExports: Double(counters.portfolioExports),
            .authenticationEnabled: authEnabled ? 1 : 0,
            .referralsCompleted: referralCount,
            .selfRedeems: Double(counters.selfRedeems)
        ]
    }
}
