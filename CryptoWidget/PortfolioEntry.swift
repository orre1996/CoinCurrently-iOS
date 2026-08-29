//
//  PortfolioEntry.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2020-12-19.
//

import Foundation
import WidgetKit
import SwiftUI

struct PortfolioEntry: TimelineEntry {
    let date: Date = Date()
    let pieModel: [Pie]
    let allPrices: [Cryptocurrency]
    let selectedCurrency: CurrencyModel
    let totalValue: Double?
    let profitLossValue: Double?
    let profitLossPercent: Double?
    let hasPro: Bool
    let isPlaceholder: Bool
    
    func copyWithPlaceholder() -> PortfolioEntry {
        PortfolioEntry(
            pieModel: pieModel,
            allPrices: allPrices,
            selectedCurrency: selectedCurrency,
            totalValue: totalValue,
            profitLossValue: profitLossValue,
            profitLossPercent: profitLossPercent,
            hasPro: hasPro,
            isPlaceholder: true
        )
    }
    
    static func empty() -> PortfolioEntry {
        PortfolioEntry(
            pieModel: [],
            allPrices: [],
            selectedCurrency: SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel(),
            totalValue: nil,
            profitLossValue: nil,
            profitLossPercent: nil,
            hasPro: false,
            isPlaceholder: true)
    }
}

extension PortfolioEntry {
    var portfolioCoins: [Pie] {
        pieModel.filter { $0.shouldShow && $0.data?.id != nil }
    }
    
    var dailyWinnerPie: Pie? {
        portfolioCoins.max {
            ($0.data?.price_change_percentage_24h_in_currency ?? -.infinity)
                < ($1.data?.price_change_percentage_24h_in_currency ?? -.infinity)
        }
    }
    
    var dailyLoserPie: Pie? {
        portfolioCoins.min {
            ($0.data?.price_change_percentage_24h_in_currency ?? .infinity)
                < ($1.data?.price_change_percentage_24h_in_currency ?? .infinity)
        }
    }
    
    var portfolioDailyChangeValue: Double? {
        let values = portfolioCoins.compactMap { dailyChangeValue(for: $0) }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +)
    }
    
    var portfolioDailyChangePercent: Double? {
        guard !portfolioCoins.isEmpty else { return nil }
        
        var weightedSum = 0.0
        var coveredValue = 0.0
        
        for pie in portfolioCoins {
            guard let percent = pie.data?.price_change_percentage_24h_in_currency else { continue }
            let value = holdingsValue(for: pie)
            weightedSum += value * percent
            coveredValue += value
        }
        
        guard coveredValue > 0 else { return nil }
        
        let percent = weightedSum / coveredValue
        guard !percent.isNaN, !percent.isInfinite else { return nil }
        
        return percent
    }
    
    func dailyChangePercent(for pie: Pie?) -> Double? {
        pie?.data?.price_change_percentage_24h_in_currency
    }
    
    func dailyChangeValue(for pie: Pie?) -> Double? {
        guard let pie, let changePercent = pie.data?.price_change_percentage_24h_in_currency else { return nil }
        return holdingsValue(for: pie) * (changePercent / 100)
    }
    
    private func holdingsValue(for pie: Pie) -> Double {
        guard let id = pie.data?.id else { return 0 }
        
        let currencyCode = selectedCurrency.code.lowercased()
        let currentPrice = allPrices.first(where: { $0.id == id })?.prices[currencyCode]
            ?? pie.data?.current_price
            ?? 0
        let amount = pieModel.getAllTransactions(of: id).getAmount()
        
        return amount * currentPrice
    }
}
