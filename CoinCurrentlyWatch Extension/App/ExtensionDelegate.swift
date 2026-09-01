//
//  ExtensionDelegate.swift
//  CoinCurrentlyWatch Extension
//
//  Created by Oscar Berggren on 2021-08-27.
//

import WatchKit
import ClockKit

class ExtensionDelegate: NSObject, WKApplicationDelegate {
    public var dataStore = CryptoDataStore()
    
    let networkManager = NetworkManagerImp.shared
    
    func applicationDidFinishLaunching(refresh: Bool = false) async -> Bool {
        scheduleNextReload()
        
        if dataStore.lastCrypto == nil || refresh {
            let success = await refreshComplicationCategory(currencyID: "bitcoin")
            self.reloadActiveComplications()

            return success
        } else {
            reloadActiveComplications()

            return false
        }
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            
                case let task as WKApplicationRefreshBackgroundTask:
                    Task {
                        task.setTaskCompletedWithSnapshot(await applicationDidFinishLaunching(refresh: true))
                    }
                    
                default:
                    task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    func handleUserActivity(_ userInfo: [AnyHashable : Any]?) { }
    
    public func refreshComplicationCategory(currencyID: String) async -> Bool {
        guard let coin: CurrencyDataModel = await networkManager.get(endpoint: .coin(id: currencyID, sparkline: true)) else {
            return false
        }
        
        dataStore.lastCrypto = coin
        reloadActiveComplications()
        
        return true
    }
    
    private func reloadActiveComplications() {
        let server = CLKComplicationServer.sharedInstance()
        for complication in server.activeComplications ?? [] {
            server.reloadTimeline(for: complication)
        }
    }
    
    private func scheduleNextReload() {
        let targetDate = Date().addingTimeInterval(60 * 30)

        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: targetDate,
            userInfo: nil,
            scheduledCompletion: { _ in }
        )
    }
    
    func getSelectedCurrency() -> CurrencyModel {
        return SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    }
}
