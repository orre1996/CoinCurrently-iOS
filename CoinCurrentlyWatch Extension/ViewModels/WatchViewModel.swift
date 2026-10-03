//
//  WatchViewModel.swift
//  CoinCurrentlyWatch Extension
//
//  Created by Oscar Berggren on 2021-08-24.
//

import Foundation
import SwiftUI

@MainActor
protocol WatchViewModel {
    var toplist: [Toplist]? { get set }
    var favorites: [Toplist] { get set }
    var downloadingCurrencyDetail: Bool { get set }
    var selectedCurrency: Toplist? { get set }
    var id: UUID { get set }
    var currentSubscription: String? { get }

    func setStartData() async
    func getToplist() async
    func getCurrency(currencyID: String) async
    func getPriceVolume(currencyID: String) async
    func toggleFavoriteStatus(currency: Toplist)
    func getTimeInChart(at: Int) -> String
}

@MainActor @Observable
final class WatchViewModelImp: WatchViewModel {
    var toplist: [Toplist]?
    var favorites = [Toplist]()

    var downloadingCurrencyDetail = false
    var selectedCurrency: Toplist?

    var id = UUID()
    
    var timer: Timer?
    
    private let networkManager = NetworkManagerImp.shared
    private let toplistRepository = ToplistRepositoryImp.shared
    private let currencyRepository = CryptoDetailRepositoryImp.shared
    private let storeKitManager: StoreKitManager
    
    var currentSubscription: String?
    
    init(storeKitManager: StoreKitManager = StoreKitManagerImp.shared) {
        self.storeKitManager = storeKitManager
    }
    
    func setStartData() async {
        await currencyRepository.ensureCacheLoaded()
        await toplistRepository.ensureCacheLoaded()
        
        currentSubscription = await storeKitManager.currentSubscription
    }
    
    func getToplist() async {
        guard let toplist: [Toplist] = await toplistRepository.getMarketToplist(
            sortOption: .mktCapDesc,
            priceChange: .sevenDays,
            platformId: nil
        ) else {
            return
        }
        
        self.toplist = toplist.sorted(by: { $0.market_cap_rank ?? 9999 < $1.market_cap_rank ?? 9999 })
    }
    
    func getCurrency(currencyID: String) async {
        let currency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
        if let details: [Toplist] = await networkManager.get(
            endpoint: .multipleCoins(
                ids: [currencyID.lowercased()],
                withSparkline: true,
                currency: currency
            )
        ) {
            self.selectedCurrency = details.first
        }
    }
    
    func getPriceVolume(currencyID: String) async {
        guard let id = selectedCurrency?.id else { return }

        if SettingsManager.shared.get(key: GlobalSettingKey.selectedTimeframe) ?? PreferredTimeframe.weekly != PreferredTimeframe.weekly {
            downloadingCurrencyDetail = true
        }
        
        if let prices: PriceVolumeModel = await currencyRepository.getCurrencyPrices(id: id, chart: String.getPreferredTimeFrameValue) {
            selectedCurrency?.sparkline_in_7d?.price = prices.prices.map({ $0.map({ (($0.last ?? 0.0) ?? 0.0 )} )} ) ?? []
            downloadingCurrencyDetail = false
        }
    }

    func toggleFavoriteStatus(currency: Toplist) {
        Task {
            self.favorites = await toplistRepository.favouriteButtonPressed(toplist: currency).sorted(by: { $0.market_cap_rank ?? 9999 < $1.market_cap_rank ?? 9999 })
        }
    }

    func getTimeInChart(at: Int) -> String {
        var value = 0
        var format = "MMM dd"
        
        switch SettingsManager.shared.get(key: GlobalSettingKey.selectedTimeframe) ?? PreferredTimeframe.weekly {
            case .daily:
                format = Date.uses24HourClock ? "HH:mm" : "hh:mm a"
                
                let hours = 0 // Date().getMinutesOfHours ?? 0 <= 0 ? 0 : 1
                
                switch at {
                    case 1:
                        value = 6 + hours
                    
                    case 2:
                        value = 12 + hours
                    
                    case 3:
                        value = 18 + hours
                    
                    default:
                        break
                }
                
            case .weekly:
                switch at {
                    case 1:
                        value = 42
                    
                    case 2:
                        value = 84
                    
                    case 3:
                        value = 126
                    
                    default:
                        break
                }
                
            case .monthly:
                switch at {
                    case 1:
                        value = 180
                    
                    case 2:
                        value = 360
                    
                    case 3:
                        value = 540
                    
                    default:
                        break
                }
        }
            
        let closestHour = Calendar.current.date(byAdding: .hour, value: -value, to: Date().nearestHour) ?? Date()
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.dateFormat = format
        let dateString = dateFormatter.string(from: closestHour)
        
        return dateString
    }
}
