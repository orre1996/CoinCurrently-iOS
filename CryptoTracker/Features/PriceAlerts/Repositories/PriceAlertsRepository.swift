//
//  PriceAlertsRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-21.
//

import Foundation
import UserNotifications
#if IS_APP
@preconcurrency import FirebaseMessaging
import UIKit
#endif

protocol PriceAlertsRepository: Actor {
    var cachedPriceAlerts: CachedData<[AlertCoin]>? { get }
    var cachedAlertPrices: CachedData<[Cryptocurrency]>? { get }
    
    func ensureCacheLoaded() async
    func ensureFCMToken() async -> Bool
    func updateUser(fcmToken: String) async
    func triggerPriceAlert() async
    func triggerBigMover() async
    func getAlertPrices(ids: [String]) async -> [Cryptocurrency]?
    func downloadRemainingCoins(ids: [String], withSparkline: Bool) async -> [Toplist]?
    func subBigMovers() async -> Bool
    func ubsubBigMovers() async -> Bool
    func sendFeedback(rating: Int, feedback: String?) async -> Bool
#if !IS_WIDGET
    func getAlerts() async -> [AlertCoin]?
    func createPriceAlert(alert: PostAlertCoin) async -> [AlertCoin]?
    func deleteAlert(alertId: String) async -> [AlertCoin]?
    func deleteLocalAlert(alertId: String) async
#endif
}

final actor PriceAlertsRepositoryImp: PriceAlertsRepository {
    static let shared = PriceAlertsRepositoryImp()

    private let networkManager: NetworkManager
    private let storageManager: CachedStorageManager
    private let storeKitManager: StoreKitManager
    private let firebaseManager: FirebaseManager

    private(set) var cachedPriceAlerts: CachedData<[AlertCoin]>?
    private(set) var cachedAlertPrices: CachedData<[Cryptocurrency]>?
    
    init(
        networkManager: NetworkManager = NetworkManagerImp.shared,
        storageManager: CachedStorageManager = CachedStorageManagerImp.shared,
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared,
        firebaseManager: FirebaseManager = FirebaseManagerImp.shared
    ) {
        self.networkManager = networkManager
        self.storageManager = storageManager
        self.storeKitManager = storeKitManager
        self.firebaseManager = firebaseManager
    }
    
    func ensureCacheLoaded() async {
        if cachedAlertPrices == nil {
            cachedAlertPrices = await storageManager.load(type: LocalStorageKeys.alertPrices)
        }
        
        if cachedPriceAlerts == nil {
            cachedPriceAlerts = await storageManager.load(type: LocalStorageKeys.priceAlerts)
        }
    }
    
    func ensureFCMToken() async -> Bool {
#if IS_APP
        guard FirebaseConfigurator.configureIfNeeded() else { return false }

        if let token = await currentFCMToken() {
            await updateUser(fcmToken: token)
            return true
        }
        
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
        
        if let token = try? await Messaging.messaging().token(), !token.isEmpty {
            await updateUser(fcmToken: token)
            return true
        }
        
        if let token = await currentFCMToken() {
            await updateUser(fcmToken: token)
            return true
        }
        
        return false
#else
        return false
#endif
    }
    
    func updateUser(fcmToken: String) async {
#if IS_APP
        let token = await resolvedFCMToken(fcmToken)
        guard !token.isEmpty else {
            return
        }
#else
        guard !fcmToken.isEmpty else {
            return
        }
        let token = fcmToken
#endif
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        
        let claims = await ReferralRepositoryImp.shared.getUser()?.user.customClaims
        let fcmMatches = claims?.fcmToken == token
        let currencyMatches = claims?.preferredCurrency?
            .caseInsensitiveCompare(currency.code) == .orderedSame
        
        if fcmMatches && currencyMatches {
            return
        }
        
        let (_, status): (EmptyResponse?, Int) = await NetworkManagerImp.shared.post(
            endpoint: .updateUser,
            bodyStruct: [
                "preferredCurrency": currency.code,
                "newFCM": token
            ]
        )
        
        if status == 200 {
            SettingsManager.shared.set(data: token, key: AppSettingKey.lastSavedFcmToken)
            _ = await ReferralRepositoryImp.shared.getUser(ignoreCache: true)
            
            let isSubscribed: Bool? = SettingsManager.shared.get(key: AppSettingKey.subscribesToBigMovers)
            if isSubscribed == nil {
                _ = await subBigMovers()
            }
        }
    }
    
    func triggerPriceAlert() async {
        let (_, _): (EmptyResponse?, Int) = await networkManager.post(
            endpoint: .triggerPriceAlert,
            bodyStruct: EmptyResponse()
        )
    }
    
    func triggerBigMover() async {
        let (_, _): (EmptyResponse?, Int) = await networkManager.post(
            endpoint: .triggerBigMover,
            bodyStruct: EmptyResponse()
        )
    }

    func getAlertPrices(ids: [String]) async -> [Cryptocurrency]? {
        await ensureCacheLoaded()
        
        guard !ids.isEmpty, let allPrices: CurrencyPricesAllCurrencies = await networkManager.get(endpoint: .coinsWithCurrencies(ids: ids)) else {
            return nil
        }

        let updated = CachedData(data: allPrices.cryptocurrencies, date: Date())
        cachedAlertPrices = updated
        await storageManager.save(type: LocalStorageKeys.alertPrices, data: updated)

        return allPrices.cryptocurrencies
    }
    
    func downloadRemainingCoins(ids: [String], withSparkline: Bool = false) async -> [Toplist]? {
        await ensureCacheLoaded()
        let hasActiveSubscription = await storeKitManager.currentSubscription != nil
        var cachedCoins: [String: CachedData<[Toplist]>] = await storageManager.load(type: LocalStorageKeys.otherCoins) ?? [:]
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        
        if let cachedCoins = cachedCoins[ids.joined() + "-" + currency.code], !cachedCoins.date.defaultCacheTimer(hasBoughtPro: hasActiveSubscription) {
            return cachedCoins.data
        }
        
        guard !ids.isEmpty else {
            return nil
        }
        
        guard let coins: [Toplist] = await networkManager.get(
            endpoint: .multipleCoins(
                ids: ids,
                withSparkline: withSparkline,
                currency: currency
            )
        ) else {
            return nil
        }

        cachedCoins[ids.joined() + "-" + currency.code] = CachedData(data: coins, date: Date())
        await storageManager.save(type: LocalStorageKeys.otherCoins, data: cachedCoins)

        return coins
    }
    
    func subBigMovers() async -> Bool {
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()

        let (_, status): (EmptyResponse?, Int) = await NetworkManagerImp.shared.post(
            endpoint: .subBigMover,
            bodyStruct: [
                "preferredCurrency": currency.code,
            ]
        )
        
        if status == 200 {
            SettingsManager.shared.set(data: true, key: AppSettingKey.subscribesToBigMovers)
            return true
        } else {
            return false
        }
    }
    
    func ubsubBigMovers() async -> Bool {
        let (_, status): (EmptyResponse?, Int) = await NetworkManagerImp.shared.post(
            endpoint: .ubsubBigMover,
            bodyStruct: EmptyResponse()
        )
        
        if status == 200 {
            SettingsManager.shared.set(data: false, key: AppSettingKey.subscribesToBigMovers)
            return false
        } else {
            return true
        }
    }
    
    func sendFeedback(rating: Int, feedback: String?) async -> Bool {
        let (_, status): (EmptyResponse?, Int) = await NetworkManagerImp.shared.post(
            endpoint: .feedback,
            bodyStruct: [
                "Rating" : "\(rating)",
                "Feedback" : feedback ?? ""
            ]
        )
        
        return status == 200
    }
    
#if !IS_WIDGET
    func getAlerts() async -> [AlertCoin]? {
        await ensureCacheLoaded()
        
        guard let priceAlerts: [AlertCoin] = await networkManager.get(endpoint: .getAlerts) else {
            return nil
        }

        let updated = CachedData(data: priceAlerts, date: Date())
        cachedPriceAlerts = updated
        await storageManager.save(type: LocalStorageKeys.priceAlerts, data: updated)

        return priceAlerts
    }
    
    func createPriceAlert(alert: PostAlertCoin) async -> [AlertCoin]? {
        let (alert, status): (AlertCoin?, Int) = await networkManager.post(endpoint: .createPriceAlert, bodyStruct: alert)
        
        guard let alert else {
            return nil
        }
        
        if status == 200 {
            await ensureCacheLoaded()
            var oldAlerts = cachedPriceAlerts?.data ?? []
            oldAlerts.append(alert)
            cachedPriceAlerts = CachedData(data: oldAlerts, date: cachedPriceAlerts?.date ?? Date())
            await storageManager.save(type: LocalStorageKeys.priceAlerts, data: oldAlerts)

            return cachedPriceAlerts?.data
        } else {
            return nil
        }
    }
    
    func deleteAlert(alertId: String) async -> [AlertCoin]? {
        let (_, statusCode): (EmptyResponse?, Int) = await networkManager.post(
            endpoint: .deleteAlert, bodyStruct: [
                "alertId" : alertId
            ]
        )
        
        if statusCode == 200 {
            await ensureCacheLoaded()
            var oldAlerts = cachedPriceAlerts?.data ?? []
            oldAlerts.removeAll(where: { $0.id == alertId })
            cachedPriceAlerts = CachedData(data: oldAlerts, date: cachedPriceAlerts?.date ?? Date())
            await storageManager.save(type: LocalStorageKeys.priceAlerts, data: oldAlerts)
            return cachedPriceAlerts?.data
        } else {
            return cachedPriceAlerts?.data
        }
    }
    
    func deleteLocalAlert(alertId: String) async {
        await ensureCacheLoaded()

        guard let alert = cachedPriceAlerts?.data.first(where: { $0.id == alertId }), !alert.isRecurringAlert else {
            return
        }
        
        var oldAlerts = cachedPriceAlerts?.data ?? []
        oldAlerts.removeAll(where: { $0.id == alertId })
        cachedPriceAlerts = CachedData(data: oldAlerts, date: cachedPriceAlerts?.date ?? Date())
        await storageManager.save(type: LocalStorageKeys.priceAlerts, data: oldAlerts)
    }
#endif

#if IS_APP
    private func resolvedFCMToken(_ fcmToken: String) async -> String {
        if !fcmToken.isEmpty {
            return fcmToken
        }
        
        if let token = await currentFCMToken() {
            return token
        }

        guard FirebaseConfigurator.configureIfNeeded() else { return "" }
        
        if let token = try? await Messaging.messaging().token(), !token.isEmpty {
            return token
        }
        
        return ""
    }

    private func currentFCMToken() async -> String? {
        guard FirebaseConfigurator.configureIfNeeded() else { return nil }

        if let token = Messaging.messaging().fcmToken, !token.isEmpty {
            return token
        }
        
        let managerToken = await firebaseManager.fcmToken
        return managerToken.isEmpty ? nil : managerToken
    }
#endif
}
