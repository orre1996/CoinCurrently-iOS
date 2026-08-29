//
//  WidgetRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-06.
//

import UIKit
import SwiftUI

protocol WidgetRepository: Actor {
    var networkManager: NetworkManager { get }
    
    func getCurrencyDetails(id: String?) async -> CurrencyDataModel?
    func getCurrencyPrices(id: String?, days: String) async -> PriceVolumeModel?
    func getMultipleCoins(ids: [String]) async -> [Toplist]?
}

final actor WidgetRepositoryImp: WidgetRepository {
    
    static let shared = WidgetRepositoryImp()
    
    var networkManager: NetworkManager

    init(networkManager: NetworkManager = NetworkManagerImp.shared) {
        self.networkManager = networkManager
    }
    
    func getCurrencyDetails(id: String?) async -> CurrencyDataModel? {
        await networkManager.get(endpoint: .coin(id: id ?? "bitcoin", sparkline: false, useFreeEndpoint: true))
    }
    
    func getCurrencyPrices(id: String?, days: String) async -> PriceVolumeModel? {
        let currency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        return await networkManager.get(endpoint: .coinPriceVolume(id: id ?? "binance", days: days, useFreeEndpoint: false, interval: nil, currency: currency))
    }
    
    func getMultipleCoins(ids: [String]) async -> [Toplist]? {
        let currency = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        return await networkManager.get(endpoint: .multipleCoins(ids: ids, withSparkline: false, currency: currency))
    }
}
