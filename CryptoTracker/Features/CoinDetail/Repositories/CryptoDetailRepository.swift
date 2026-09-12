//
//  CategoryDetailsViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-18.
//

import SwiftUI
import Combine
#if canImport(SignalRClient)
import SignalRClient
#endif

private struct SubCoinRequest: Codable {
    let coinIds: [String]
    let currencies: [String]
}

protocol CryptoDetailRepository: Actor {
    var cachedCryptoDetail: [String: CachedData<CurrencyDataModel>] { get }
    var cachedCryptoPrices: [String: CachedData<PriceVolumeModel>] { get }
    var cachedCryptoCandles: [String: CachedData<CandleStickChartModel>] { get }

    var cachedBitcoin: CachedData<CurrencyDataModel>? { get }
    var cachedEthereum: CachedData<CurrencyDataModel>? { get }
    var widgetCurrencies: [Toplist] { get }
    
    func ensureCacheLoaded() async
    func migrateSavedCoins() async
    func loadCachedDataForCoin(id: String, chart: TimeCharts) async
    func getCurrencyDetails(id: String?) async -> CurrencyDataModel?
    func getCurrencyPrices(id: String?, chart: TimeCharts) async -> PriceVolumeModel?
    func getCompareCurrencyPrices(mainId: String?, compareId: String?, chart: TimeCharts) async -> (PriceVolumeModel?, PriceVolumeModel?)
    func getPriceModel(id: String, chart: TimeCharts) async -> PriceVolumeModel?
    func getCandleChart(id: String?, days: String) async -> CandleStickChartModel?
    func getBitcoin() async -> CurrencyDataModel?
    func getEthereum() async -> CurrencyDataModel?
    func getImage(url: String?) async -> UIImage?
    func connectSignalR(onMessage: (@Sendable (CGSimplePriceUpdate) -> Void)?) async -> Bool
    func getCurrency(coinId: String) async -> Bool
    func getCurrencies(coinIds: [String]) async -> Bool
    func disconnectSignalR() async
}

final actor CryptoDetailRepositoryImp: CryptoDetailRepository {
    public static let shared = CryptoDetailRepositoryImp()
    
    private let networkManager: NetworkManager
    private let storageManager: CachedStorageManager
    private let firebaseManager: FirebaseManager
    
    private(set) var cachedCryptoDetail: [String: CachedData<CurrencyDataModel>]
    private(set) var cachedCryptoPrices: [String: CachedData<PriceVolumeModel>]
    private(set) var cachedCryptoCandles: [String: CachedData<CandleStickChartModel>]
    
    var cachedBitcoin: CachedData<CurrencyDataModel>?
    var cachedEthereum: CachedData<CurrencyDataModel>?
    var widgetCurrencies = [Toplist]()
    
#if canImport(SignalRClient)
    private var hubConnection: HubConnection?
    private var signalRReconnectTask: Task<Void, Never>?
    private var isSignalRReconnecting = false
#endif
    private var subscribedCoinIds: [String] = []
    private var onSignalRMessage: (@Sendable (CGSimplePriceUpdate) -> Void)?
    
    init(
        networkManager: NetworkManager = NetworkManagerImp.shared,
        storageManager: CachedStorageManager = CachedStorageManagerImp.shared,
        firebaseManager: FirebaseManager = FirebaseManagerImp.shared
    ) {
        self.networkManager = networkManager
        self.storageManager = storageManager
        self.firebaseManager = firebaseManager
        self.cachedBitcoin = nil
        self.cachedEthereum = nil
        self.widgetCurrencies = []
        self.cachedCryptoDetail = [:]
        self.cachedCryptoPrices = [:]
        self.cachedCryptoCandles = [:]
    }
    
    private var hasLoadedFromStorage = false

    func ensureCacheLoaded() async {
        guard !hasLoadedFromStorage else { return }
        hasLoadedFromStorage = true
        widgetCurrencies = await storageManager.load(type: LocalStorageKeys.widgets) ?? []
        if let bitcoin: CurrencyDataModel = await networkManager.getCached(endpoint: .coin(id: "bitcoin", sparkline: true, useFreeEndpoint: true)) {
            cachedBitcoin = CachedData(data: bitcoin, date: Date())
        }
        if let ethereum: CurrencyDataModel = await networkManager.getCached(endpoint: .coin(id: "ethereum", sparkline: true, useFreeEndpoint: true)) {
            cachedEthereum = CachedData(data: ethereum, date: Date())
        }
    }

    func migrateSavedCoins() async {
        await ensureCacheLoaded()
        let oldIds: [String] = WidgetReloadService.shared.getSavedCurrencies().filter({ !$0.isEmpty })
        guard !oldIds.isEmpty, widgetCurrencies.isEmpty else { return }
        widgetCurrencies = oldIds.map({ Toplist(id: $0) })
        await saveWidgetCurrenciesToStorageAndUpdateWidgets()
        UserDefaults(suiteName: String.groupIdentifier)?.removeObject(forKey: "savedCoin")
    }

    func loadCachedDataForCoin(id: String, chart: TimeCharts) async {
        await ensureCacheLoaded()

        if let detail: CurrencyDataModel = await networkManager.getCached(endpoint: .coin(id: id, sparkline: true, useFreeEndpoint: true)) {
            cachedCryptoDetail[id] = CachedData(data: detail, date: Date())
        }

        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        if let prices: PriceVolumeModel = await networkManager.getCached(
            endpoint: .coinPriceVolume(
                id: id,
                days: chart.days,
                useFreeEndpoint: true,
                interval: chart.interval,
                currency: currency
            )
        ) {
            let divider = chart.days == "max" ? max(1, (prices.prices?.count ?? 0) / 400) : 1
            if let filtered = filterPriceVolume(priceVolume: prices, divider: divider) {
                cachedCryptoPrices["\(id)-\(chart.days)"] = CachedData(data: filtered, date: Date())
            }
        }

        if let dataPoints: [Candle] = await networkManager.getCached(
            endpoint: .candleStick(
                id: id,
                days: chart.days,
                useFreeEndpoint: true,
                currency: currency
            )
        ) {
            let candleChartModel = CandleStickChartModel(candle: dataPoints)
            cachedCryptoCandles["\(id)-\(chart.days)"] = CachedData(data: candleChartModel, date: Date())
        }
    }

    func getCurrencyDetails(id: String?) async -> CurrencyDataModel? {
        await ensureCacheLoaded()
        guard let id else { return nil }

        guard let cryptoDetails: CurrencyDataModel = await networkManager.get(endpoint: .coin(id: id, sparkline: true, useFreeEndpoint: true)) else {
            return nil
        }
        
        cachedCryptoDetail[id] = CachedData(data: cryptoDetails, date: Date())
        return cryptoDetails
    }
    
    func getCompareCurrencyDetails(
        mainId: String?,
        compareId: String?
    ) async -> (CurrencyDataModel?, CurrencyDataModel?) {
        await ensureCacheLoaded()
        guard let mainId, let compareId else {
            return (nil, nil)
        }
        
        async let mainDetail: CurrencyDataModel? = networkManager.get(endpoint: .coin(id: mainId, useFreeEndpoint: true))
        async let compareDetail: CurrencyDataModel? = networkManager.get(endpoint: .coin(id: compareId, useFreeEndpoint: true))
        
        let (main, compare) = await (mainDetail, compareDetail)
        
        if let main {
            cachedCryptoDetail[mainId] = CachedData(data: main, date: Date())
        }
        if let compare {
            cachedCryptoDetail[compareId] = CachedData(data: compare, date: Date())
        }
        
        return (main, compare)
    }

    func getCurrencyPrices(
        id: String?,
        chart: TimeCharts
    ) async -> PriceVolumeModel? {
        await ensureCacheLoaded()
        guard let id else { return nil }
        
        guard let cryptoPrices: PriceVolumeModel = await getPriceModelInternal(id: id, chart: chart, isFromCompare: false) else {
            return nil
        }
        
        cachedCryptoPrices["\(id)-\(chart.days)"] = CachedData(data: cryptoPrices, date: Date())
        return cryptoPrices
    }
    
    func getCompareCurrencyPrices(
        mainId: String?,
        compareId: String?,
        chart: TimeCharts
    ) async -> (PriceVolumeModel?, PriceVolumeModel?) {
        await ensureCacheLoaded()
        guard let mainId, let compareId else {
            return (nil, nil)
        }
        
        async let mainPrices = getPriceModelInternal(id: mainId, chart: chart, isFromCompare: true)
        async let comparePrices = getPriceModelInternal(id: compareId, chart: chart, isFromCompare: true)
        
        let (main, compare) = await (mainPrices, comparePrices)

        if let main {
            cachedCryptoPrices["\(mainId)-\(chart.days)-compare"] = CachedData(data: main, date: Date())
        }
        if let compare {
            cachedCryptoPrices["\(compareId)-\(chart.days)-compare"] = CachedData(data: compare, date: Date())
        }
        
        return (main, compare)
    }
    
    func getPriceModel(id: String, chart: TimeCharts) async -> PriceVolumeModel? {
        return await getPriceModelInternal(id: id, chart: chart, isFromCompare: false)
    }

    private func getPriceModelInternal(id: String, chart: TimeCharts, isFromCompare: Bool) async -> PriceVolumeModel? {
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        let prices: PriceVolumeModel? = await networkManager.get(
            endpoint: .coinPriceVolume(
                id: id,
                days: chart.days,
                useFreeEndpoint: true,
                interval: chart.interval,
                currency: currency
            )
        )
        
        let divider: Int
        if chart.days == "max" && !isFromCompare {
            divider = max(1, (prices?.prices?.count ?? 0) / 400)
        } else if isFromCompare {
            divider = 2
        } else {
            divider = 1
        }
        return filterPriceVolume(priceVolume: prices, divider: divider)
    }
    
    func filterPriceVolume(priceVolume: PriceVolumeModel?, divider: Int) -> PriceVolumeModel? {
        let divider = max(1, divider)
        guard var priceVolume else {
            return nil
        }
        
        priceVolume.prices = filterDataPoints(
            priceVolume.prices,
            maxElement: priceVolume.prices?.compactMap({ $0.last }).compactMap({ $0 }).max() ?? 0.0,
            minElement: priceVolume.prices?.compactMap({ $0.last }).compactMap({ $0 }).min() ?? 0.0,
            divider: divider
        )
        
        priceVolume.total_volumes = filterDataPoints(
            priceVolume.total_volumes,
            maxElement: priceVolume.total_volumes?.compactMap({ $0.last }).compactMap({ $0 }).max() ?? 0.0,
            minElement: priceVolume.total_volumes?.compactMap({ $0.last }).compactMap({ $0 }).min() ?? 0.0,
            divider: divider
        )
        
        priceVolume.market_caps = filterDataPoints(
            priceVolume.market_caps,
            maxElement: priceVolume.market_caps?.compactMap({ $0.last }).compactMap({ $0 }).max() ?? 0.0,
            minElement: priceVolume.market_caps?.compactMap({ $0.last }).compactMap({ $0 }).min() ?? 0.0,
            divider: divider
        )
        
        return priceVolume
    }
    
    func getCandleChart(id: String?, days: String) async -> CandleStickChartModel? {
        await ensureCacheLoaded()
        guard let id else { return nil }
        
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        let dataPoints: [Candle]? = await networkManager.get(
            endpoint: .candleStick(
                id: id,
                days: days,
                useFreeEndpoint: true,
                currency: currency
            )
        )

        let candleChartModel = CandleStickChartModel(candle: dataPoints)

        if dataPoints != nil {
            cachedCryptoCandles["\(id)-\(days)"] = CachedData(data: candleChartModel, date: Date())
        }
        
        return candleChartModel
    }

    func getBitcoin() async -> CurrencyDataModel? {
        await ensureCacheLoaded()
        let bitcoin: CurrencyDataModel? = await networkManager.get(endpoint: .coin(id: "bitcoin", sparkline: true, useFreeEndpoint: true))
        
        if let bitcoin {
            cachedBitcoin = CachedData(data: bitcoin, date: Date())
        }

        return bitcoin
    }
    
    func getEthereum() async -> CurrencyDataModel? {
        await ensureCacheLoaded()
        let ethereum: CurrencyDataModel? = await networkManager.get(endpoint: .coin(id: "ethereum", sparkline: true, useFreeEndpoint: true))
        
        if let ethereum {
            cachedEthereum = CachedData(data: ethereum, date: Date())
        }

        return ethereum
    }
    
    func getImage(url: String?) async -> UIImage? {
        guard let url, let imageData: Data = await networkManager.get(endpoint: .image(url: url)) else { return nil }
        
        return UIImage(data: imageData)
    }
    
    func connectSignalR(onMessage: (@Sendable (CGSimplePriceUpdate) -> Void)? = nil) async -> Bool {
#if canImport(SignalRClient)
        onSignalRMessage = onMessage
        
        if hubConnection != nil {
            return true
        }
        
        guard await firebaseManager.getUserToken() != nil else {
            print("🔴 SignalR connection failed: could not generate auth token")
            return false
        }
        
        var options = HttpConnectionOptions()
        options.accessTokenFactory = { [firebaseManager] in
            await firebaseManager.getUserToken()
        }
        options.transport = .longPolling
        
        let connection = HubConnectionBuilder()
            .withUrl(url: "\(serverBaseUrl)/premium/connect", options: options)
            .withLogHandler(logHandler: SignalRLogHandler(onRecoverableFailure: {
                Task {
                    await CryptoDetailRepositoryImp.shared.scheduleSignalRReconnect()
                }
            }))
            .withAutomaticReconnect()
            .build()
        
        await connection.onReconnected {
            await CryptoDetailRepositoryImp.shared.resubscribeToSignalRCoin()
        }
        
        await connection.onClosed { _ in
            await CryptoDetailRepositoryImp.shared.handleSignalRClosed()
        }
        
        await connection.on("weiner") { (message: String) in
            Task {
                await CryptoDetailRepositoryImp.shared.processSignalRMessage(message)
            }
        }
        
        do {
            try await connection.start()
            hubConnection = connection
            return true
        } catch {
            print("🔴 SignalR connection failed: \(error.localizedDescription)")
            hubConnection = nil
            return false
        }
#else
        return false
#endif
    }
    
    func getCurrency(coinId: String) async -> Bool {
        await getCurrencies(coinIds: [coinId])
    }
    
    func getCurrencies(coinIds: [String]) async -> Bool {
        subscribedCoinIds = coinIds
            .map { $0.lowercased() }
            .filter { !$0.isEmpty }
        
        guard !subscribedCoinIds.isEmpty else { return false }
        
        let selectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        let currencyCodes = [selectedCurrency.code.lowercased()]
        
        let (_, status): (EmptyResponse?, Int) = await networkManager.post(
            endpoint: .subCoin,
            bodyStruct: SubCoinRequest(
                coinIds: subscribedCoinIds,
                currencies: currencyCodes
            )
        )
        
        return status == 200
    }
    
    func disconnectSignalR() async {
#if canImport(SignalRClient)
        await tearDownSignalRConnection(clearSubscription: true)
#endif
    }
    
#if canImport(SignalRClient)
    private func tearDownSignalRConnection(clearSubscription: Bool) async {
        signalRReconnectTask?.cancel()
        signalRReconnectTask = nil
        
        if let hubConnection {
            await hubConnection.stop()
        }
        hubConnection = nil
        
        if clearSubscription {
            onSignalRMessage = nil
            subscribedCoinIds = []
            isSignalRReconnecting = false
        }
    }
    
    private func scheduleSignalRReconnect() {
        guard !subscribedCoinIds.isEmpty, onSignalRMessage != nil else { return }
        
        signalRReconnectTask?.cancel()
        signalRReconnectTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            await reconnectSignalRAfterFailure()
        }
    }
    
    private func reconnectSignalRAfterFailure() async {
        guard !isSignalRReconnecting else { return }
        guard let callback = onSignalRMessage, !subscribedCoinIds.isEmpty else { return }
        
        isSignalRReconnecting = true
        defer {
            isSignalRReconnecting = false
            signalRReconnectTask = nil
        }
        
        print("🟡 SignalR long poll failed, reconnecting...")
        await tearDownSignalRConnection(clearSubscription: false)
        
        let connected = await connectSignalR(onMessage: callback)
        if connected {
            _ = await getCurrencies(coinIds: subscribedCoinIds)
        }
    }
    
    private func resubscribeToSignalRCoin() async {
        guard !subscribedCoinIds.isEmpty else { return }
        _ = await getCurrencies(coinIds: subscribedCoinIds)
    }
    
    private func handleSignalRClosed() async {
        guard !subscribedCoinIds.isEmpty, onSignalRMessage != nil, !isSignalRReconnecting else { return }
        scheduleSignalRReconnect()
    }
#endif
    
    private func processSignalRMessage(_ message: String) {
        guard let data = message.data(using: .utf8),
              let update = try? JSONDecoder().decode(CGSimplePriceUpdate.self, from: data),
              let coinId = update.coinId else {
            return
        }

        let existing = cachedCryptoDetail[coinId]?.data ?? CurrencyDataModel(id: coinId)
        let updated = update.apply(to: existing)
        cachedCryptoDetail[coinId] = CachedData(data: updated, date: Date())

        if coinId == "bitcoin" {
            cachedBitcoin = CachedData(data: updated, date: Date())
        } else if coinId == "ethereum" {
            cachedEthereum = CachedData(data: updated, date: Date())
        }

        onSignalRMessage?(update)
    }

    private func saveWidgetCurrenciesToStorageAndUpdateWidgets() async {
        await storageManager.save(type: LocalStorageKeys.widgets, data: widgetCurrencies)
#if !os(watchOS)
        WidgetReloadService.shared.forceUpdateWidgets(type: .currencies)
#endif
    }
    
    private func filterDataPoints(_ dataPoints: [[Double?]]?, maxElement: Double?, minElement: Double?, divider: Int) -> [[Double?]]? {
        return dataPoints?.enumerated().compactMap { index, element in
            index % divider == 0 || element.last == maxElement || element.last == minElement ? element : nil
        }
    }
}

#if canImport(SignalRClient)
private struct SignalRLogHandler: LogHandler {
    private let onRecoverableFailure: @Sendable () -> Void
    
    init(onRecoverableFailure: @escaping @Sendable () -> Void) {
        self.onRecoverableFailure = onRecoverableFailure
    }
    
    func log(
        logLevel: LogLevel,
        message: LogMessage,
        file: String,
        function: String,
        line: UInt
    ) {
        let messageText = message.description
        
        if messageText.contains("(LongPolling transport) Unexpected response code: 503")
            || messageText.contains("(LongPolling transport) Unexpected response code: 502")
            || messageText.contains("(LongPolling transport) Unexpected response code: 504") {
            onRecoverableFailure()
            return
        }
        
        print(messageText)
    }
}
#endif
