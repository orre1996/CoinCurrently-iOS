//
//  Array+Extensions.swift
//  Cryptocurrently
//
//  Created by Oscar Berggren on 2020-12-08.
//

import Foundation
import SwiftUI

infix operator +?: AdditionPrecedence

func +? <T>(lhs: [T]?, rhs: [T]?) -> [T]? {
    guard let lhs = lhs, let rhs = rhs else { return nil }
    return lhs + rhs
}

extension Array {
    func takeElements(elementCount: Int) -> Array {
        if (elementCount > count) {
            return Array(self[0..<count])
        }
        return Array(self[0..<elementCount])
    }

    subscript(safely index: Int) -> Element? {
        if index < count && index >= 0 {
            return self[index]
        }
        
        return nil
    }

    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Array where Element == String {
    var stringSeparatedByComma: String {
        if self.isEmpty {  return "" }
        return String(self.map({ $0 + "," }).joined().dropLast())
    }
}

extension Array where Element == Double {
    var normalized: [Double] {
        guard !self.allSatisfy({ $0 == self.first }) else {
            return self.compactMap({ _ in 0.5 })
        }

        guard let min = self.min(), let max = self.max() else {
            return []
        }

        return self.map({ ($0 - min) / (max - min) })
    }

    var defaultTimeStamps: [Double] {
        guard !self.isEmpty else { return [] }

        let steps: Double = 1.0 / Double(self.count)
        return self.indices.map { Double($0) * steps }.normalized
    }

    var getTrimmedVolume: [Double] {
        var firstNumber = 1

        if self.count >= 100 {
            let count = Double(self.count).roundToHundreds
            let temp = String("\(count)")

            firstNumber = temp.digits.first ?? 0

            if self.count >= 1000 {
                firstNumber *= 10
                firstNumber += temp.digits[1]
            }
        }

        return self.enumerated().compactMap { tuple in
            tuple.offset.isMultiple(of: firstNumber) ? tuple.element : nil
        }
    }

    func normalizedCustom(max: CGFloat, min: CGFloat) -> [Double] {
        return self.map {
            let a = $0 - min
            let b = max - min
            return b == 0 ? 0 : a / b
        }
    }

    func point(at index: Int, rect: CGSize, dropCount: Int = 0) -> CGPoint {
        let normalizedPrices = Array(self.normalized.dropLast(dropCount))
        let point = normalizedPrices[safely: index] ?? 0
        let x = rect.width * CGFloat(index) / CGFloat(normalizedPrices.count - 1)
        let y = (1 - point) * rect.height
        return CGPoint(x: x, y: y.isNaN ? 0.5 * rect.height : y)
    }
}

extension Array where Element == CGFloat {
    var normalized: [CGFloat] {
        if let min = self.min(), let max = self.max() {
            return self.map({ ($0 - min) / (max - min) })
        }
        
        return []
    }
    
    func normalizedCustom(max: CGFloat, min: CGFloat) -> [CGFloat] {
        return self.map({ ($0 - min) / (max - min) })
    }
}

extension Array where Element: Equatable {
    func contains(array: [Element]) -> Bool {
        for item in array {
            if !self.contains(item) { return false }
        }
        return true
    }
}

extension Array where Element == [Double] {
    func highest() -> Double {
        let highest = self.min(by: {$0.last ?? 0.0 > $1.last ?? 0.0})
        return Double(highest?.last ?? 0.0)
    }
    
    func lowest() -> Double {
        let lowest = self.min(by: {$0.last ?? 0.0 < $1.last ?? 0.0})
        return Double(lowest?.last ?? 0.0)
    }
}

extension Array where Element: Codable {
    func asJSONString() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension Array where Element == NewSwapTransaction {
    private func filtered(
        after: Date = .distantPast,
        before: Date = Date()
    ) -> [NewSwapTransaction] {
        return self.filter { tx in
            guard tx.date > after && tx.date < before else {
                return false
            }
            
            return true
        }
    }
    
    var buyTransactions: [NewTransaction] {
        return map { $0.buyTransaction }
    }
    
    
    func buyAmount(
        after: Date = .distantPast,
        before: Date = Date()
    ) -> Double {
        map { $0.buyTransaction }
            .sumAmounts(
                of: .buy,
                after: after,
                before: before
            )
    }
    
    func sellAmount(
        after: Date = .distantPast,
        before: Date = Date()
    ) -> Double {
        map { $0.sellTransaction }
            .sumAmounts(
                of: .sell,
                after: after,
                before: before
            )
    }
}

extension Array where Element == NewTransaction {
    func ofType(_ type: NewTransactionType) -> [NewTransaction] {
        self.filter { $0.transactionType == type }
    }
    
    private func filtered(
        type: NewTransactionType? = nil,
        withTransfers: Bool = true,
        after: Date = .distantPast,
        before: Date = Date()
    ) -> [NewTransaction] {
        return self.filter { tx in
            if let type = type {
                guard tx.transactionType == type else {
                    return false
                }
                
                if !withTransfers, (type.isTransfer || type == .importAddress) {
                    return false
                }
            }
            
            guard tx.date >= after && tx.date <= before else {
                return false
            }
            
            return true
        }
    }

    func sumAmounts(
        of type: NewTransactionType,
        withTransfers: Bool = true,
        after: Date = .distantPast,
        before: Date = Date()
    ) -> Double {
        filtered(type: type, withTransfers: withTransfers, after: after, before: before)
            .map { $0.amount }
            .reduce(0, +)
    }
    
    func getAmount(
        withTransfers: Bool = true,
        after: Date = .distantPast,
        before: Date = Date(),
    ) -> Double {
        sumAmounts(of: .importAddress, withTransfers: withTransfers, after: after, before: before)
        + sumAmounts(of: .buy, after: after, before: before)
        + sumAmounts(of: .transferIn, withTransfers: withTransfers, after: after, before: before)
        - sumAmounts(of: .sell, after: after, before: before)
        - sumAmounts(of: .transferOut, withTransfers: withTransfers, after: after, before: before)
    }

    func afterDate(_ date: Date) -> [NewTransaction] {
        filtered(after: date)
    }
    
    func beforeDate(_ date: Date) -> [NewTransaction] {
        filtered(before: date)
    }
    
    private func priceMultiplier(
        prices: [String: Double]?,
        showCurrency: String,
        transactionCurrency: String
    ) -> Double {
        let show = prices?[showCurrency.lowercased()] ?? 0
        let trans = prices?[transactionCurrency.lowercased()] ?? 0
        return show / trans
    }
    
    private func safeValue(_ value: Double) -> Double? {
        guard !value.isNaN && !value.isInfinite else { return nil }
        return value
    }
    
    func getTotalFees(
        prices: [String: Double]?,
        showCurrency: String
    ) -> Double? {
        let fees = compactMap { tx -> Double? in
            guard let _ = tx.pricePerCoin else { return nil }
            let multiplier = priceMultiplier(prices: prices, showCurrency: showCurrency, transactionCurrency: tx.currency)
            return tx.fee * multiplier
        }.reduce(0, +)

        return safeValue(fees) ?? 0
    }
    
    func getTotalCost(
        prices: [String: Double]?,
        showCurrency: String,
        extraTransactions: [NewTransaction] = []
    ) -> Double? {
        let total = ofType(.buy).compactMap { tx -> Double? in
            guard let price = tx.pricePerCoin else { return nil }
            let multiplier = priceMultiplier(prices: prices, showCurrency: showCurrency, transactionCurrency: tx.currency)
            return (price * tx.amount * multiplier) + tx.fee
        }.reduce(0, +)
    
        return safeValue(total) ?? 0
    }
    
    var totalBuyAmount: Double {
        sumAmounts(of: .buy)
    }

    func getAverageCost(
        prices: [String: Double]?,
        showCurrency: String
    ) -> Double? {
        let showCurrency = showCurrency.lowercased()
        let totalCost = ofType(.buy).reduce(0) { sum, tx in
            let multiplier = priceMultiplier(prices: prices, showCurrency: showCurrency, transactionCurrency: tx.currency)
            return sum + tx.amount * ((tx.pricePerCoin ?? 1) * multiplier)
        }
        
        return safeValue(totalCost / totalBuyAmount)
    }
    
    func getProfitPercent(
        prices: [String: Double]?,
        showCurrency: String,
        withTransfers: Bool = true,
    ) -> Double? {
        let avgCost = getAverageCost(prices: prices, showCurrency: showCurrency) ?? 1
        let originalCost = totalBuyAmount * avgCost
        
        let transactionSellCost = ofType(.sell).reduce(0) { sum, tx in
            let multiplier = priceMultiplier(prices: prices, showCurrency: showCurrency, transactionCurrency: tx.currency)
            return sum + tx.amount * ((tx.pricePerCoin ?? 0) * multiplier)
        }

        let currentValue = getAmount(withTransfers: withTransfers) * (prices?[showCurrency.lowercased()] ?? 0) + transactionSellCost
        return safeValue(((currentValue / originalCost) - 1) * 100)
    }
    
    func getProfitValue(
        prices: [String: Double]?,
        showCurrency: String,
        withTransfers: Bool = true
    ) -> Double? {
        guard let prices, !prices.isEmpty else { return 0 }
        
        let price = prices[showCurrency.lowercased()] ?? 0
        let importValues = sumAmounts(of: .importAddress, withTransfers: withTransfers) * price
        let inValue = sumAmounts(of: .transferIn, withTransfers: withTransfers) * price
        let outValue = sumAmounts(of: .transferOut, withTransfers: withTransfers) * price
        
        let profitPercent = getProfitPercent(prices: prices, showCurrency: showCurrency, withTransfers: false) ?? 0
        let avgCost = getAverageCost(prices: prices, showCurrency: showCurrency) ?? 0
        
        let profit = (profitPercent / 100) * (avgCost * totalBuyAmount) + importValues + inValue - outValue
        return safeValue(profit)
    }
}

extension Array where Element == NewPortfolioModel {
    var defaultWalletName: String {
        let imports = map { $0.imports.count }.reduce(0, +)
        return imports == 0 ? "Wallet" : "Wallet \(imports)"
    }
    
    func getAllTransactions(of id: String?) -> [NewTransaction] {
        let coin = filter { $0.id == id }
        let transactions = coin.flatMap { $0.transactions }
        let buySwapTransactions = coin.map { $0.swaps }
            .flatMap { $0.buyTransactions }
        let swapSellTransactions = flatMap { $0.swaps }
            .filter { $0.fromCurrencyId == id }
            .compactMap { $0.sellTransaction }
        let importTransactions = coin.flatMap { $0.imports }
            .compactMap { $0.importTransaction }
        let tokensTransactions = flatMap { $0.imports }
            .flatMap { importItem in
                (importItem.tokenInfos ?? []).map { token in
                    (token, importItem.date)
                }
            }
            .filter { $0.0.tokenId == id }
            .map { token, date in
                token.toAddressImport(with: date).importTransaction
            }
            .compactMap { $0 }
        
        return transactions + buySwapTransactions + swapSellTransactions + importTransactions + tokensTransactions
    }
    
    var allIds: [String] {
        return map { $0.id } + flatMap { $0.imports }
            .flatMap { $0.tokenInfos ?? [] }
            .compactMap { $0.tokenId }
    }
}

extension Array where Element == Pie {
    func pie(containing event: (any PortfolioEvent)?) -> Pie? {
        switch event {
        case let transaction as NewTransaction:
            return first { $0.transactions.contains(transaction) }
        case let swap as NewSwapTransaction:
            return first { $0.swaps.contains(swap) }
        case let importEvent as AddressImport:
            return first { $0.imports.contains(importEvent) }
        default:
            return nil
        }
    }
    
    var allWallets: [AddressImport] {
        flatMap { $0.imports }
    }

    var allTransactionsCount: Int {
        map { $0.transactions.count + $0.swaps.count + $0.imports.count }.reduce(0, +)
    }
    
    func getAllTransactions(of id: String?) -> [NewTransaction] {
        let coin = filter { $0.data?.id == id }
        let transactions = coin.flatMap { $0.transactions }
        let buySwapTransactions = coin.map { $0.swaps }
            .flatMap { $0.buyTransactions }
        let swapSellTransactions = flatMap { $0.swaps }
            .filter { $0.fromCurrencyId == id }
            .map { $0.sellTransaction }
        let importTransactions = coin.flatMap { $0.imports }
            .compactMap { $0.importTransaction }
        let tokensTransactions = flatMap { $0.imports }
            .flatMap { importItem in
                (importItem.tokenInfos ?? []).map { token in
                    (token, importItem.date)
                }
            }
            .filter { $0.0.tokenId == id }
            .map { token, date in
                token.toAddressImport(with: date).importTransaction
            }
            .compactMap { $0 }
        
        return transactions + buySwapTransactions + swapSellTransactions + importTransactions + tokensTransactions
    }
    
    func swapSellTransactions(for id: String?) -> [NewTransaction] {
        return flatMap { $0.swaps }
            .filter { $0.fromCurrencyId == id }
            .map { $0.sellTransaction }
    }

    func groupedTransactions(
        types: [NewTransactionType],
        on dateOption: DateOption,
        coinNames: [Toplist],
    ) -> [Date: [any PortfolioEvent]] {

        var result: [Date: [any PortfolioEvent]] = [:]
        let calendar = Calendar.current
        let now = Date()

        // 1) Resolve date range
        let range: ClosedRange<Date>? = {
            switch dateOption {
            case .all:
                return nil
            case .lastWeek:
                return calendar.date(byAdding: .day, value: -7, to: now)!...now
            case .lastMonth:
                return calendar.date(byAdding: .month, value: -1, to: now)!...now
            case .lastThreeMonths:
                return calendar.date(byAdding: .month, value: -3, to: now)!...now
            case .lastSixMonths:
                return calendar.date(byAdding: .month, value: -6, to: now)!...now
            case .lastYear:
                return calendar.date(byAdding: .year, value: -1, to: now)!...now
            case .yearToDate:
                let start = calendar.date(
                    from: calendar.dateComponents([.year], from: now)
                )!
                return start...now
            case let .custom(start, end):
                guard let start, let end else {
                    return nil
                }

                return start...end
            }
        }()

        for pie in self {

            // ✅ Coin filter (nil or empty = include all)
            if !coinNames.isEmpty {
                let matches = coinNames.contains { name in
                    pie.data?.symbol?.localizedCaseInsensitiveContains(name.symbol ?? "") == true ||
                    pie.data?.name?.localizedCaseInsensitiveContains(name.name ?? "") == true ||
                    pie.data?.id?.localizedCaseInsensitiveContains(name.id ?? "") == true
                }

                if !matches { continue }
            }

            // Transactions
            for tx in pie.transactions {
                if !types.isEmpty,
                   !types.contains(tx.transactionType) { continue }

                guard isInRange(tx.date, range) else { continue }

                let day = calendar.startOfDay(for: tx.date)
                result[day, default: []].append(tx)
            }

            // Swaps
            for swap in pie.swaps {
                if !types.isEmpty,
                   !types.contains(.swap) { continue }

                guard isInRange(swap.date, range) else { continue }

                let day = calendar.startOfDay(for: swap.date)
                result[day, default: []].append(swap)
            }

            // Imports
            for importEvent in pie.imports {
                if !types.isEmpty,
                   !types.contains(.importAddress) { continue }

                guard isInRange(importEvent.date, range) else { continue }

                let day = calendar.startOfDay(for: importEvent.date)
                result[day, default: []].append(importEvent)
            }
        }

        // Sort newest first
        for key in result.keys {
            result[key]?.sort { $0.date > $1.date }
        }

        return result
    }

    private func isInRange(_ date: Date, _ range: ClosedRange<Date>?) -> Bool {
        guard let range else { return true } // .all
        return range.contains(date)
    }
}
