//
//  GlobalFunctions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-01-09.
//

import Foundation
import SwiftUI

#if !os(watchOS)
    import WidgetKit
#endif

class GlobalFunctions {
    @AppStorage("savedCoin", store: UserDefaults(suiteName: .groupIdentifier))
    var savedCoins: Data = Data()

    @AppStorage("savedPortfolio", store: UserDefaults(suiteName: .groupIdentifier))
    var savedPortfolio: Data = Data()

    // nonisolated(unsafe) - accessed from actors and widget providers
    nonisolated(unsafe) public static let shared = GlobalFunctions()

   func getSavedCurrencies() -> [String] {
        let savedCurrency = (try? JSONDecoder().decode(Array<String>.self, from: savedCoins)) ?? [String]()
        return savedCurrency
    }
     
    // DON'T REMOVE
    func getSavedPortfolio() -> [PortfolioCurrencyModel] {
        guard let savedPortfolio = (try? JSONDecoder().decode([PortfolioCurrencyModel].self, from: savedPortfolio)) else { return [] }
        return savedPortfolio.filter({ $0.id != "" })
    }

    enum WidgetTypes {
        case currencies
        case portfolio
        case all
    }
    
    func forceUpdateWidgets(type: WidgetTypes = .all) {
#if !os(watchOS)
        if type == .portfolio {
            WidgetCenter.shared.reloadTimelines(ofKind: "My_Portfolio_Widget")
        } else if type == .currencies {
            WidgetCenter.shared.reloadTimelines(ofKind: "My_Widget")
            WidgetCenter.shared.reloadTimelines(ofKind: "CoinCurrently_Duo_Widget")
            WidgetCenter.shared.reloadTimelines(ofKind: "My_Quad_Widget")
            WidgetCenter.shared.reloadTimelines(ofKind: "My_Multi_Widget")
        } else {
            WidgetCenter.shared.reloadAllTimelines()
        }
#endif
    }
    
#if !os(watchOS)
    func getPortfolioProfitLossValue(of portfolio: [Pie]?, coinPrices: [Cryptocurrency], showCurrency: String) -> Double? {
        guard let portfolio else {
            return nil
        }
        
        if portfolio.isEmpty || coinPrices.isEmpty {
            return 0
        }
        
        var profitLoss = 0.0
        var hasEntryPrices = false
        
        for pie in portfolio {
            let coin = portfolio.getAllTransactions(of: pie.data?.id)
            let prices = coinPrices.first(where: { $0.id == pie.data?.id })?.prices
            
            if let profit = getProfitLossOfCoin(transactions: coin, coinPrices: prices, showCurrency: showCurrency) {
                profitLoss += profit
                hasEntryPrices = true
            }
        }
        
        if !hasEntryPrices {
            return 0.0
        }
        
        return profitLoss
    }
    
    func getProfitLossOfCoin(
        transactions: [NewTransaction]?,
        coinPrices: [String: Double]?,
        showCurrency: String
    ) -> Double? {
        return transactions?.getProfitValue(prices: coinPrices, showCurrency: showCurrency)
    }
    
    func getPortfolioProfitLossPercent(
        of portfolio: [Pie]?,
        coinPrices: [Cryptocurrency],
        showCurrency: String
    ) -> Double {
        if portfolio?.isEmpty ?? true || coinPrices.isEmpty {
            return 0.0
        }
        
        var totalProfit = 0.0
        var totalSpent = 0.0
        
        for pie in portfolio ?? [] {
            let coin = portfolio?.getAllTransactions(of: pie.data?.id)
            let prices = coinPrices.first(where: { $0.id == pie.data?.id })?.prices

            if coin?.getProfitPercent(prices: prices, showCurrency: showCurrency) != nil {
                totalProfit += coin?.getProfitValue(prices: prices, showCurrency: showCurrency, withTransfers: false) ?? 0.0
                totalSpent += (coin?.totalBuyAmount ?? 0.0) * (coin?.getAverageCost(prices: prices, showCurrency: showCurrency) ?? 0.0)
            }
        }
        
        let percent = totalProfit / totalSpent
        
        if percent.isNaN || percent.isInfinite {
            return 0.0
        }
        
        return percent * 100
    }
#endif
}
