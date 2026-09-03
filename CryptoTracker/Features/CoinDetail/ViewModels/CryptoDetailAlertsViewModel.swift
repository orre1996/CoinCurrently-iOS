//
//  CryptoDetailAlertsViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/2/26.
//

import Foundation
@preconcurrency import UserNotifications

@MainActor
@Observable
final class CryptoDetailAlertsViewModel {
    var alerts: [AlertCoin]?

    private var coinId: String?

    private let priceAlertsRepository: PriceAlertsRepository
    private let storeKitManager: StoreKitManager

    init(
        priceAlertsRepository: PriceAlertsRepository = PriceAlertsRepositoryImp.shared,
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared
    ) {
        self.priceAlertsRepository = priceAlertsRepository
        self.storeKitManager = storeKitManager
    }

    func load(coinId: String?) async {
        self.coinId = coinId
        await priceAlertsRepository.ensureCacheLoaded()
        await getPriceAlerts()
    }

    func allAlertsCount() async -> Int {
        await priceAlertsRepository.cachedPriceAlerts?.data.count ?? 0
    }

    func checkIfUserEnabledPush() async -> Bool {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        switch status {
        case .authorized:
            return true
        case .notDetermined, .denied, .provisional, .ephemeral:
            return false
        @unknown default:
            return false
        }
    }

    func hasBoughtPro() async -> Bool {
        await storeKitManager.currentSubscription != nil
    }

    func getPriceAlerts() async {
        if let alerts = await priceAlertsRepository.getAlerts() {
            self.alerts = filteredAlerts(alerts)
        } else if self.alerts?.isEmpty ?? true {
            alerts = []
        }
    }

    func addPriceAlert(alertCoin: PostAlertCoin) async -> AddPriceAlertResult {
        guard await priceAlertsRepository.ensureFCMToken() else {
            return .fcmTokenUnavailable
        }

        if let alerts = await priceAlertsRepository.createPriceAlert(alert: alertCoin) {
            self.alerts = filteredAlerts(alerts)
            return .success
        } else {
            return .failure
        }
    }

    func deleteAlert(alert: AlertCoin) async {
        self.alerts = alerts?.filter({ $0.id != alert.id })

        if let alerts = await priceAlertsRepository.deleteAlert(alertId: alert.id) {
            self.alerts = filteredAlerts(alerts)
        }
    }

    private func filteredAlerts(_ alerts: [AlertCoin]) -> [AlertCoin] {
        alerts
            .lazy
            .filter({ $0.coinId == self.coinId?.lowercased() })
            .sorted(by: {
                ($0.createdDate.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ) ?? Date())
                > ($1.createdDate.convertStringToDate(dateFormat: .yyyyMMddTHHmmssSSSZ) ?? Date())
            })
    }
}
