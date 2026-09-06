//
//  PortfolioTaxExportBuilder.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 8/17/26.
//

import Foundation

enum PortfolioTaxExportBuilder {
    private struct ExportEntry {
        let date: Date
        let row: String
    }
    
    static func koinlyCSV(from portfolio: [Pie]) -> String {
        let header = "Date,Sent Amount,Sent Currency,Received Amount,Received Currency,Fee Amount,Fee Currency,Description"
        return buildCSV(header: header, from: portfolio) { coin, transaction in
            koinlyRow(coin: coin, transaction: transaction)
        } swapRow: { swap in
            koinlySwapRow(swap: swap)
        } importRow: { coin, importEvent in
            koinlyImportRow(coin: coin, importEvent: importEvent)
        }
    }
    
    static func coinTrackerCSV(from portfolio: [Pie]) -> String {
        let header = "Date,Received Quantity,Received Currency,Sent Quantity,Sent Currency,Fee Amount,Fee Currency,Tag"
        return buildCSV(header: header, from: portfolio) { coin, transaction in
            coinTrackerRow(coin: coin, transaction: transaction)
        } swapRow: { swap in
            coinTrackerSwapRow(swap: swap)
        } importRow: { coin, importEvent in
            coinTrackerImportRow(coin: coin, importEvent: importEvent)
        }
    }
    
    static func tokenTaxCSV(from portfolio: [Pie]) -> String {
        let header = "Type,BuyAmount,BuyCurrency,SellAmount,SellCurrency,FeeAmount,FeeCurrency,Exchange,Group,Comment,Date"
        return buildCSV(header: header, from: portfolio) { coin, transaction in
            tokenTaxRow(coin: coin, transaction: transaction)
        } swapRow: { swap in
            tokenTaxSwapRow(swap: swap)
        } importRow: { coin, importEvent in
            tokenTaxImportRow(coin: coin, importEvent: importEvent)
        }
    }
    
    static func zenLedgerCSV(from portfolio: [Pie]) -> String {
        let header = "Timestamp,Type,IN Amount,IN Currency,OUT Amount,OUT Currency,Fee Amount,Fee Currency,Exchange,US Based"
        return buildCSV(header: header, from: portfolio) { coin, transaction in
            zenLedgerRow(coin: coin, transaction: transaction)
        } swapRow: { swap in
            zenLedgerSwapRow(swap: swap)
        } importRow: { coin, importEvent in
            zenLedgerImportRow(coin: coin, importEvent: importEvent)
        }
    }
    
    private static func buildCSV(
        header: String,
        from portfolio: [Pie],
        transactionRow: (String, PortfolioTransaction) -> String,
        swapRow: (PortfolioSwapTransaction) -> String,
        importRow: (String, AddressImport) -> String
    ) -> String {
        var entries: [ExportEntry] = []
        
        for pie in portfolio {
            let coin = coinSymbol(for: pie)
            
            for transaction in pie.transactions {
                entries.append(ExportEntry(date: transaction.date, row: transactionRow(coin, transaction)))
            }
            
            for swap in pie.swaps {
                entries.append(ExportEntry(date: swap.date, row: swapRow(swap)))
            }
            
            for importEvent in pie.imports {
                entries.append(ExportEntry(date: importEvent.date, row: importRow(coin, importEvent)))
            }
        }
        
        let rows = entries
            .sorted { $0.date > $1.date }
            .map(\.row)
        
        return ([header] + rows).joined(separator: "\n")
    }
    
    private static func coinSymbol(for pie: Pie) -> String {
        pie.data?.symbol?.uppercased() ?? pie.data?.name ?? ""
    }
    
    private static func tradeValue(amount: Double, pricePerCoin: Double?) -> Double {
        amount * (pricePerCoin ?? 0)
    }
    
    private static func parsedBalance(_ balance: String) -> Double? {
        let normalized = balance
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(normalized)
    }
    
    private static func csvField(_ value: String) -> String {
        value.replacingOccurrences(of: ",", with: ".")
    }
    
    private static func csvNumericField(_ value: Double?) -> String {
        guard let value else { return "" }
        return csvField(value.description)
    }
    
    private static func feeFields(amount: Double, currency: String) -> (amount: String, currency: String) {
        guard amount > 0 else { return ("", "") }
        return (csvNumericField(amount), csvField(currency.uppercased()))
    }
    
    // MARK: - Koinly
    
    private static func koinlyRow(coin: String, transaction: PortfolioTransaction) -> String {
        let fees = feeFields(amount: transaction.fee, currency: transaction.currency)
        let value = tradeValue(amount: transaction.amount, pricePerCoin: transaction.pricePerCoin)
        
        switch transaction.transactionType {
        case .buy:
            return koinlyColumns(
                date: transaction.date.portfolioExportDateTimeUTC,
                sentAmount: csvNumericField(value),
                sentCurrency: csvField(transaction.currency.uppercased()),
                receivedAmount: csvNumericField(transaction.amount),
                receivedCurrency: csvField(coin),
                feeAmount: fees.amount,
                feeCurrency: fees.currency,
                description: csvField(transaction.note)
            )
        case .sell:
            return koinlyColumns(
                date: transaction.date.portfolioExportDateTimeUTC,
                sentAmount: csvNumericField(transaction.amount),
                sentCurrency: csvField(coin),
                receivedAmount: csvNumericField(value),
                receivedCurrency: csvField(transaction.currency.uppercased()),
                feeAmount: fees.amount,
                feeCurrency: fees.currency,
                description: csvField(transaction.note)
            )
        case .transferIn, .importAddress:
            return koinlyColumns(
                date: transaction.date.portfolioExportDateTimeUTC,
                sentAmount: "",
                sentCurrency: "",
                receivedAmount: csvNumericField(transaction.amount),
                receivedCurrency: csvField(coin),
                feeAmount: "",
                feeCurrency: "",
                description: csvField(transaction.note)
            )
        case .transferOut:
            return koinlyColumns(
                date: transaction.date.portfolioExportDateTimeUTC,
                sentAmount: csvNumericField(transaction.amount),
                sentCurrency: csvField(coin),
                receivedAmount: "",
                receivedCurrency: "",
                feeAmount: "",
                feeCurrency: "",
                description: csvField(transaction.note)
            )
        case .swap:
            return koinlyColumns(
                date: transaction.date.portfolioExportDateTimeUTC,
                sentAmount: "",
                sentCurrency: "",
                receivedAmount: "",
                receivedCurrency: "",
                feeAmount: "",
                feeCurrency: "",
                description: csvField(transaction.note)
            )
        }
    }
    
    private static func koinlySwapRow(swap: PortfolioSwapTransaction) -> String {
        let fees = feeFields(amount: swap.fee, currency: swap.selectedCurrency)
        
        return koinlyColumns(
            date: swap.date.portfolioExportDateTimeUTC,
            sentAmount: csvNumericField(swap.fromAmount),
            sentCurrency: csvField(swap.fromCurrencySymbol.uppercased()),
            receivedAmount: csvNumericField(swap.toAmount),
            receivedCurrency: csvField(swap.toCurrencySymbol.uppercased()),
            feeAmount: fees.amount,
            feeCurrency: fees.currency,
            description: csvField(swap.note)
        )
    }
    
    private static func koinlyImportRow(coin: String, importEvent: AddressImport) -> String {
        let amount = parsedBalance(importEvent.balance)
        let description = [importEvent.walletName, importEvent.address]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        
        return koinlyColumns(
            date: importEvent.date.portfolioExportDateTimeUTC,
            sentAmount: "",
            sentCurrency: "",
            receivedAmount: csvNumericField(amount),
            receivedCurrency: csvField(coin),
            feeAmount: "",
            feeCurrency: "",
            description: csvField(description)
        )
    }
    
    private static func koinlyColumns(
        date: String,
        sentAmount: String,
        sentCurrency: String,
        receivedAmount: String,
        receivedCurrency: String,
        feeAmount: String,
        feeCurrency: String,
        description: String
    ) -> String {
        [date, sentAmount, sentCurrency, receivedAmount, receivedCurrency, feeAmount, feeCurrency, description]
            .joined(separator: ",")
    }
    
    // MARK: - CoinTracker
    
    private static func coinTrackerRow(coin: String, transaction: PortfolioTransaction) -> String {
        let fees = feeFields(amount: transaction.fee, currency: transaction.currency)
        let value = tradeValue(amount: transaction.amount, pricePerCoin: transaction.pricePerCoin)
        
        switch transaction.transactionType {
        case .buy:
            return coinTrackerColumns(
                date: transaction.date.coinTrackerExportDateTimeUTC,
                receivedQuantity: csvNumericField(transaction.amount),
                receivedCurrency: csvField(coin),
                sentQuantity: csvNumericField(value),
                sentCurrency: csvField(transaction.currency.uppercased()),
                feeAmount: fees.amount,
                feeCurrency: fees.currency,
                tag: ""
            )
        case .sell:
            return coinTrackerColumns(
                date: transaction.date.coinTrackerExportDateTimeUTC,
                receivedQuantity: csvNumericField(value),
                receivedCurrency: csvField(transaction.currency.uppercased()),
                sentQuantity: csvNumericField(transaction.amount),
                sentCurrency: csvField(coin),
                feeAmount: fees.amount,
                feeCurrency: fees.currency,
                tag: ""
            )
        case .transferIn, .importAddress:
            return coinTrackerColumns(
                date: transaction.date.coinTrackerExportDateTimeUTC,
                receivedQuantity: csvNumericField(transaction.amount),
                receivedCurrency: csvField(coin),
                sentQuantity: "",
                sentCurrency: "",
                feeAmount: "",
                feeCurrency: "",
                tag: ""
            )
        case .transferOut:
            return coinTrackerColumns(
                date: transaction.date.coinTrackerExportDateTimeUTC,
                receivedQuantity: "",
                receivedCurrency: "",
                sentQuantity: csvNumericField(transaction.amount),
                sentCurrency: csvField(coin),
                feeAmount: "",
                feeCurrency: "",
                tag: ""
            )
        case .swap:
            return coinTrackerColumns(
                date: transaction.date.coinTrackerExportDateTimeUTC,
                receivedQuantity: "",
                receivedCurrency: "",
                sentQuantity: "",
                sentCurrency: "",
                feeAmount: "",
                feeCurrency: "",
                tag: ""
            )
        }
    }
    
    private static func coinTrackerSwapRow(swap: PortfolioSwapTransaction) -> String {
        let fees = feeFields(amount: swap.fee, currency: swap.selectedCurrency)
        
        return coinTrackerColumns(
            date: swap.date.coinTrackerExportDateTimeUTC,
            receivedQuantity: csvNumericField(swap.toAmount),
            receivedCurrency: csvField(swap.toCurrencySymbol.uppercased()),
            sentQuantity: csvNumericField(swap.fromAmount),
            sentCurrency: csvField(swap.fromCurrencySymbol.uppercased()),
            feeAmount: fees.amount,
            feeCurrency: fees.currency,
            tag: ""
        )
    }
    
    private static func coinTrackerImportRow(coin: String, importEvent: AddressImport) -> String {
        coinTrackerColumns(
            date: importEvent.date.coinTrackerExportDateTimeUTC,
            receivedQuantity: csvNumericField(parsedBalance(importEvent.balance)),
            receivedCurrency: csvField(coin),
            sentQuantity: "",
            sentCurrency: "",
            feeAmount: "",
            feeCurrency: "",
            tag: ""
        )
    }
    
    private static func coinTrackerColumns(
        date: String,
        receivedQuantity: String,
        receivedCurrency: String,
        sentQuantity: String,
        sentCurrency: String,
        feeAmount: String,
        feeCurrency: String,
        tag: String
    ) -> String {
        [date, receivedQuantity, receivedCurrency, sentQuantity, sentCurrency, feeAmount, feeCurrency, tag]
            .joined(separator: ",")
    }
    
    // MARK: - TokenTax
    
    private static func tokenTaxRow(coin: String, transaction: PortfolioTransaction) -> String {
        let fees = feeFields(amount: transaction.fee, currency: transaction.currency)
        let value = tradeValue(amount: transaction.amount, pricePerCoin: transaction.pricePerCoin)
        
        switch transaction.transactionType {
        case .buy:
            return tokenTaxColumns(
                type: "Trade",
                buyAmount: csvNumericField(transaction.amount),
                buyCurrency: csvField(coin),
                sellAmount: csvNumericField(value),
                sellCurrency: csvField(transaction.currency.uppercased()),
                feeAmount: fees.amount,
                feeCurrency: fees.currency,
                comment: csvField(transaction.note),
                date: transaction.date.portfolioExportDateTimeUTC
            )
        case .sell:
            return tokenTaxColumns(
                type: "Trade",
                buyAmount: csvNumericField(value),
                buyCurrency: csvField(transaction.currency.uppercased()),
                sellAmount: csvNumericField(transaction.amount),
                sellCurrency: csvField(coin),
                feeAmount: fees.amount,
                feeCurrency: fees.currency,
                comment: csvField(transaction.note),
                date: transaction.date.portfolioExportDateTimeUTC
            )
        case .transferIn, .importAddress:
            return tokenTaxColumns(
                type: "Income",
                buyAmount: csvNumericField(transaction.amount),
                buyCurrency: csvField(coin),
                sellAmount: "",
                sellCurrency: "",
                feeAmount: "",
                feeCurrency: "",
                comment: csvField(transaction.note),
                date: transaction.date.portfolioExportDateTimeUTC
            )
        case .transferOut:
            return tokenTaxColumns(
                type: "Spending",
                buyAmount: "",
                buyCurrency: "",
                sellAmount: csvNumericField(transaction.amount),
                sellCurrency: csvField(coin),
                feeAmount: "",
                feeCurrency: "",
                comment: csvField(transaction.note),
                date: transaction.date.portfolioExportDateTimeUTC
            )
        case .swap:
            return tokenTaxColumns(
                type: "Trade",
                buyAmount: "",
                buyCurrency: "",
                sellAmount: "",
                sellCurrency: "",
                feeAmount: "",
                feeCurrency: "",
                comment: csvField(transaction.note),
                date: transaction.date.portfolioExportDateTimeUTC
            )
        }
    }
    
    private static func tokenTaxSwapRow(swap: PortfolioSwapTransaction) -> String {
        let fees = feeFields(amount: swap.fee, currency: swap.selectedCurrency)
        
        return tokenTaxColumns(
            type: "Trade",
            buyAmount: csvNumericField(swap.toAmount),
            buyCurrency: csvField(swap.toCurrencySymbol.uppercased()),
            sellAmount: csvNumericField(swap.fromAmount),
            sellCurrency: csvField(swap.fromCurrencySymbol.uppercased()),
            feeAmount: fees.amount,
            feeCurrency: fees.currency,
            comment: csvField(swap.note),
            date: swap.date.portfolioExportDateTimeUTC
        )
    }
    
    private static func tokenTaxImportRow(coin: String, importEvent: AddressImport) -> String {
        let description = [importEvent.walletName, importEvent.address]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        
        return tokenTaxColumns(
            type: "Income",
            buyAmount: csvNumericField(parsedBalance(importEvent.balance)),
            buyCurrency: csvField(coin),
            sellAmount: "",
            sellCurrency: "",
            feeAmount: "",
            feeCurrency: "",
            comment: csvField(description),
            date: importEvent.date.portfolioExportDateTimeUTC
        )
    }
    
    private static func tokenTaxColumns(
        type: String,
        buyAmount: String,
        buyCurrency: String,
        sellAmount: String,
        sellCurrency: String,
        feeAmount: String,
        feeCurrency: String,
        comment: String,
        date: String
    ) -> String {
        [type, buyAmount, buyCurrency, sellAmount, sellCurrency, feeAmount, feeCurrency, "CoinCurrently", "", comment, date]
            .joined(separator: ",")
    }
    
    // MARK: - ZenLedger
    
    private static func zenLedgerRow(coin: String, transaction: PortfolioTransaction) -> String {
        let fees = feeFields(amount: transaction.fee, currency: transaction.currency)
        let value = tradeValue(amount: transaction.amount, pricePerCoin: transaction.pricePerCoin)
        
        switch transaction.transactionType {
        case .buy:
            return zenLedgerColumns(
                timestamp: transaction.date.portfolioExportDateTimeUTC,
                type: "buy",
                inAmount: csvNumericField(transaction.amount),
                inCurrency: csvField(coin),
                outAmount: csvNumericField(value),
                outCurrency: csvField(transaction.currency.uppercased()),
                feeAmount: fees.amount,
                feeCurrency: fees.currency
            )
        case .sell:
            return zenLedgerColumns(
                timestamp: transaction.date.portfolioExportDateTimeUTC,
                type: "sell",
                inAmount: csvNumericField(value),
                inCurrency: csvField(transaction.currency.uppercased()),
                outAmount: csvNumericField(transaction.amount),
                outCurrency: csvField(coin),
                feeAmount: fees.amount,
                feeCurrency: fees.currency
            )
        case .transferIn, .importAddress:
            return zenLedgerColumns(
                timestamp: transaction.date.portfolioExportDateTimeUTC,
                type: "receive",
                inAmount: csvNumericField(transaction.amount),
                inCurrency: csvField(coin),
                outAmount: "",
                outCurrency: "",
                feeAmount: "",
                feeCurrency: ""
            )
        case .transferOut:
            return zenLedgerColumns(
                timestamp: transaction.date.portfolioExportDateTimeUTC,
                type: "send",
                inAmount: "",
                inCurrency: "",
                outAmount: csvNumericField(transaction.amount),
                outCurrency: csvField(coin),
                feeAmount: "",
                feeCurrency: ""
            )
        case .swap:
            return zenLedgerColumns(
                timestamp: transaction.date.portfolioExportDateTimeUTC,
                type: "trade",
                inAmount: "",
                inCurrency: "",
                outAmount: "",
                outCurrency: "",
                feeAmount: "",
                feeCurrency: ""
            )
        }
    }
    
    private static func zenLedgerSwapRow(swap: PortfolioSwapTransaction) -> String {
        let fees = feeFields(amount: swap.fee, currency: swap.selectedCurrency)
        
        return zenLedgerColumns(
            timestamp: swap.date.portfolioExportDateTimeUTC,
            type: "trade",
            inAmount: csvNumericField(swap.toAmount),
            inCurrency: csvField(swap.toCurrencySymbol.uppercased()),
            outAmount: csvNumericField(swap.fromAmount),
            outCurrency: csvField(swap.fromCurrencySymbol.uppercased()),
            feeAmount: fees.amount,
            feeCurrency: fees.currency
        )
    }
    
    private static func zenLedgerImportRow(coin: String, importEvent: AddressImport) -> String {
        zenLedgerColumns(
            timestamp: importEvent.date.portfolioExportDateTimeUTC,
            type: "receive",
            inAmount: csvNumericField(parsedBalance(importEvent.balance)),
            inCurrency: csvField(coin),
            outAmount: "",
            outCurrency: "",
            feeAmount: "",
            feeCurrency: ""
        )
    }
    
    private static func zenLedgerColumns(
        timestamp: String,
        type: String,
        inAmount: String,
        inCurrency: String,
        outAmount: String,
        outCurrency: String,
        feeAmount: String,
        feeCurrency: String
    ) -> String {
        [timestamp, type, inAmount, inCurrency, outAmount, outCurrency, feeAmount, feeCurrency, "CoinCurrently", ""]
            .joined(separator: ",")
    }
}
