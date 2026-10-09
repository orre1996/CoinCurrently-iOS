//
//  SettingsManager.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-18.
//

import SwiftUI

protocol SettingKeyable {
    var rawValue: String { get }
    var data: Data? { get }
}

enum GlobalSettingKey: String, SettingKeyable {
    case selectedCurrency
    case changesInPercent = "showChangeInPercent"
    case selectedTimeframe = "preferredTimeFrame"
    
    var data: Data? {
        return UserDefaults(suiteName: .groupIdentifier)?.data(forKey: self.rawValue)
    }
}

enum AppSettingKey: String, SettingKeyable {
    case transactionInGraph
    case lockRotation
    case authenticationEnabled = "isAuthenticationEnabled"
    case webSocketEnabled
    case startTab = "startTab"
    case startMarketPage
    case latestTab
    case isGraphLinear
    case graphType
    case timeframe
    case searchHistory
    case hidePortfolioValues
    case hasClosedApp
    case toplistSortOption
    case toplistPriceChange
    case nftsSortOption
    case nftPlatform
    case categoriesSortOption
    case exchangesSortOption
    case derivativesSortOption
    case derivativeDetailSortOption
    case cryptoDetailSortOption
    case nftDetailSortOption
    case exchangeDetailSortOption
    case lastSavedFcmToken
    case subscribesToBigMovers
    case isNFTChartFiat
    case candleChartSelected
    case hasOnboardedSettings
    case ratingPopupDate
    case actionRatingPopupDate
    case hasRatingPopupDate
    case currentWhatsNewVersion = "3.2"
    case storedWhatsNewVersion
    case colorBlindnessFilter
    case selectedLanguage
    case isPortfolioPieChartShowing
    case treasuriesEntityFilter
    case treasuriesCoinId
    case hasHomeFavorites

    var data: Data? {
        return UserDefaults(suiteName: .groupIdentifier)?.data(forKey: self.rawValue)
    }
}

enum NewsSettingKey: String, SettingKeyable {
    case lastNewsCategory = "lastNewsCategory-1"

    var data: Data? {
        return UserDefaults(suiteName: .groupIdentifier)?.data(forKey: self.rawValue)
    }
}

class SettingsManager {
    // nonisolated(unsafe) - used as default param in NewsRepositoryImp and elsewhere
    nonisolated(unsafe) static let shared = SettingsManager()

    func get<T: Decodable>(key: SettingKeyable) -> T? {
        guard let data = key.data, let object = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }

        return object
    }

    func set<T: Codable>(data: T, key: SettingKeyable) {
        guard let data = try? JSONEncoder().encode(data) else { return }

        UserDefaults(suiteName: .groupIdentifier)?.set(data, forKey: key.rawValue)
    }

    // MARK: - Migrated from WidgetReloadService (app-only settings)

    func getCandleChartSelected() -> Bool {
        get(key: AppSettingKey.candleChartSelected) ?? false
    }

    func setCandleChart(enabled: Bool) {
        set(data: enabled, key: AppSettingKey.candleChartSelected)
    }

    func isWebSocketEnabled(hasPro: Bool) -> Bool {
        get(key: AppSettingKey.webSocketEnabled) ?? hasPro
    }

    func isColorBlindnessFilterEnabled() -> Bool {
        get(key: AppSettingKey.colorBlindnessFilter) ?? false
    }

    func setColorBlindnessFilterEnabled(_ enabled: Bool) {
        set(data: enabled, key: AppSettingKey.colorBlindnessFilter)
    }

    func getHasOnboardedSettings() -> Date? {
        get(key: AppSettingKey.hasOnboardedSettings)
    }

    func setHasOnboardedSettings(date: Date) {
        set(data: date, key: AppSettingKey.hasOnboardedSettings)
    }

    func getLatestTab() -> Int {
        let startTab: StartTab = get(key: AppSettingKey.startTab) ?? .home
        switch startTab {
        case .lastUsed:
            return get(key: AppSettingKey.latestTab) ?? 0
        case .home: return 0
        case .portfolio: return 1
        case .market: return 2
        case .news: return 3
        case .more: return 4
        }
    }

    func getRatingPopupDate() -> Date? {
        guard let hasRatingPopup: Bool = get(key: AppSettingKey.hasRatingPopupDate), hasRatingPopup else {
            return nil
        }
        return get(key: AppSettingKey.ratingPopupDate)
    }

    func setRatingPopupDate(date: Date) {
        set(data: true, key: AppSettingKey.hasRatingPopupDate)
        set(data: date, key: AppSettingKey.ratingPopupDate)
    }

    func getActionRatingDate() -> Date? {
        get(key: AppSettingKey.actionRatingPopupDate)
    }

    func setActionRatingDate(date: Date) {
        set(data: date, key: AppSettingKey.actionRatingPopupDate)
    }

    func getKeyExists(key: String) -> Bool {
        UserDefaults.standard.value(forKey: key) as? Bool ?? false
    }

    func setKey(key: String) {
        UserDefaults.standard.setValue(true, forKey: key)
    }

    /// Removes all keys from the app group UserDefaults (shared with widgets)
    func purge() {
        guard let suite = UserDefaults(suiteName: .groupIdentifier) else { return }
        suite.dictionaryRepresentation().keys.forEach { suite.removeObject(forKey: $0) }
    }

    /// Removes all keys from UserDefaults.standard (app-only, e.g. getKeyExists/setKey keys)
    func purgeStandardUserDefaults() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        UserDefaults.standard.synchronize()
    }

    /// Sets default values after a purge (e.g. after account removal)
    func setDefaults() {
        set(data: CurrencyModel(), key: GlobalSettingKey.selectedCurrency)
        set(data: true, key: GlobalSettingKey.changesInPercent)
        set(data: PreferredTimeframe.weekly, key: GlobalSettingKey.selectedTimeframe)
        setCandleChart(enabled: false)
        set(data: [String: SearchResult](), key: AppSettingKey.searchHistory)
        set(data: false, key: AppSettingKey.authenticationEnabled)
        set(data: 0, key: AppSettingKey.latestTab)
        set(data: StartTab.home, key: AppSettingKey.startTab)
        set(data: StartMarketPage.currencies, key: AppSettingKey.startMarketPage)
        set(data: false, key: AppSettingKey.hidePortfolioValues)
        set(data: false, key: AppSettingKey.lockRotation)
        set(data: false, key: AppSettingKey.colorBlindnessFilter)
    }
}
