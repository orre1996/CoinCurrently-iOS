//
//  PriceAlertsViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-21.
//

import Foundation
import Combine
@preconcurrency import UserNotifications

@MainActor
protocol PriceAlertsViewModel: ObservableObject {
    var filteredToplist: [Toplist]? { get }
    var alertPrices: [Cryptocurrency]? { get }
    var hasPush: Bool { get }
    var alerts: [AlertCoin]? { get }
    var groups: [String] { get }
    var isPriceAlertsOn: Bool { get set }

    func checkIfUserEnabledPush() async
    func getFilteredToplist() async
    func getAlertPrices(ids: [String]) async
    func getCoin(id: String?) -> Toplist?
    func getPriceAlerts() async
    func deleteAlert(alert: AlertCoin) async
    func addPriceAlert(alertCoin: PostAlertCoin) async -> AddPriceAlertResult
    func toggleBigMover() async
    func getSelectedCoin(id: String) async -> CurrencyDataModel?
    func setGroups()
    func sendFeedback(rating: Int, feedback: String?) async -> Bool
}

@MainActor @Observable
final class PriceAlertsViewModelImp: PriceAlertsViewModel {
    var filteredToplist: [Toplist]?
    var alertPrices: [Cryptocurrency]?
    var hasPush = true
    var alerts: [AlertCoin]?
    var groups: [String] = []
    var isPriceAlertsOn: Bool
    
    private let priceAlertsRepository: PriceAlertsRepository
    private let toplistRepository: ToplistRepository
    private let storeKitManager: StoreKitManager
    private let cryptoDetailRepository: CryptoDetailRepository
    
    init(
        priceAlertsRepository: PriceAlertsRepository = PriceAlertsRepositoryImp.shared,
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared,
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared
    ) {
        self.priceAlertsRepository = priceAlertsRepository
        self.toplistRepository = toplistRepository
        self.storeKitManager = storeKitManager
        self.cryptoDetailRepository = cryptoDetailRepository
        
        self.isPriceAlertsOn = SettingsManager.shared.get(key: AppSettingKey.subscribesToBigMovers) ?? true
    }
    
    func setStartData() async {
        await priceAlertsRepository.ensureCacheLoaded()
        await toplistRepository.ensureCacheLoaded()
        
        await checkIfUserEnabledPush()
        
        if let toplist = await toplistRepository.cachedSmallToplist?.data {
            filteredToplist = toplist.sorted(by: { $0.market_cap_rank ?? 9999 < $1.market_cap_rank ?? 9999 })
        }
        
        if let prices = await priceAlertsRepository.cachedAlertPrices?.data {
            self.alertPrices = prices
        }
        
        if let alerts = await priceAlertsRepository.cachedPriceAlerts?.data {
            self.alerts = alerts
            setGroups()
        }
    }
    
    func checkIfUserEnabledPush() async {
        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .notDetermined, .denied:
            self.hasPush = false
            
        case .authorized:
            self.hasPush = true
            
        default:
            self.hasPush = false
        }
    }

    func getFilteredToplist() async {
        if let toplist = await toplistRepository.getSmallToplist() {
            let toplist = toplist.sorted(by: { $0.market_cap_rank ?? 9999 < $1.market_cap_rank ?? 9999 })
            await getAlertPrices(ids: toplist.compactMap({ $0.id }))
            filteredToplist = toplist
            
            let toplistIdSet = Set(filteredToplist?.compactMap { $0.id } ?? [])
            let alertCoinIdsNotInToplist = Array(Set(alerts?.compactMap { $0.coinId } ?? []).subtracting(toplistIdSet))
            if !alertCoinIdsNotInToplist.isEmpty {
                await getRemainingItems(ids: alertCoinIdsNotInToplist)
            }
        }
    }

    func getAlertPrices(ids: [String]) async {
        if let prices = await priceAlertsRepository.getAlertPrices(ids: ids) {
            self.alertPrices = prices
        }
    }
    
    func getCoin(id: String?) -> Toplist? {
        guard let id else {
            return nil
        }

        return filteredToplist?.filter({ $0.id == id }).first
    }
    
    func getPriceAlerts() async {
        if let alerts = await priceAlertsRepository.getAlerts() {
            self.alerts = alerts
        } else if self.alerts?.isEmpty ?? true {
            alerts = []
        }
    }
    
    func deleteAlert(alert: AlertCoin) async {
        if let alerts = await priceAlertsRepository.deleteAlert(alertId: alert.id) {
            self.alerts = alerts
            setGroups()
        }
    }

    func addPriceAlert(alertCoin: PostAlertCoin) async -> AddPriceAlertResult {
        guard await priceAlertsRepository.ensureFCMToken() else {
            return .fcmTokenUnavailable
        }
        
        if let alerts = await priceAlertsRepository.createPriceAlert(alert: alertCoin) {
            self.alerts = alerts
            setGroups()
            return .success
        } else {
            return .failure
        }
    }
    
    func setGroups() {
        var groups = [String: Int]()
        
        for alert in alerts ?? [] {
            let marketCap = filteredToplist?.filter({ $0.id == alert.coinId }).first?.market_cap_rank ?? 9999
            groups[alert.coinId] = marketCap
        }
        
        let sortedDictionary = Array(groups.sorted(by: { $0.1 < $1.1 }))
        let sortedKeyArray = sortedDictionary.map({ $0.key })
        self.groups = sortedKeyArray
    }
    
    func toggleBigMover() async {
        let isOn: Bool
        if isPriceAlertsOn {
            isOn = await priceAlertsRepository.ubsubBigMovers()
        } else {
            isOn = await priceAlertsRepository.subBigMovers()
        }
        
        SettingsManager.shared.set(data: isOn, key: AppSettingKey.subscribesToBigMovers)
        isPriceAlertsOn = isOn
    }
    
    func getSelectedCoin(id: String) async -> CurrencyDataModel? {
        return await cryptoDetailRepository.getCurrencyDetails(id: id)
    }
    
    func hasBoughtPro() async -> Bool {
        return await storeKitManager.currentSubscription != nil
    }
    
    private func getRemainingItems(ids: [String]) async {
        if let coins = await priceAlertsRepository.downloadRemainingCoins(ids: ids, withSparkline: false) {
            filteredToplist?.append(contentsOf: coins)
            filteredToplist = filteredToplist?.sorted(by: { ($0.market_cap_rank ?? 9999) < ($1.market_cap_rank ?? 9999) }) ?? []
        }
    }
    
    func sendFeedback(rating: Int, feedback: String?) async -> Bool {
        return await priceAlertsRepository.sendFeedback(rating: rating, feedback: feedback)
    }
}
