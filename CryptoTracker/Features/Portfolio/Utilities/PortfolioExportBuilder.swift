//
//  PortfolioExportBuilder.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/2/26.
//

import Foundation

enum PortfolioExportFormat {
    case csv
    case json
    case plainText
    case koinly
    case coinTracker
    case tokenTax
    case zenLedger

    var isTaxSoftware: Bool {
        switch self {
        case .koinly, .coinTracker, .tokenTax, .zenLedger:
            return true
        case .csv, .json, .plainText:
            return false
        }
    }

    var fileExtension: String {
        switch self {
        case .json:
            return "json"
        case .plainText:
            return "txt"
        case .csv, .koinly, .coinTracker, .tokenTax, .zenLedger:
            return "csv"
        }
    }

    var fileName: String {
        switch self {
        case .csv, .json, .plainText:
            return "CoinCurrently-Portfolio"
        case .koinly:
            return "CoinCurrently-Portfolio-Koinly"
        case .coinTracker:
            return "CoinCurrently-Portfolio-CoinTracker"
        case .tokenTax:
            return "CoinCurrently-Portfolio-TokenTax"
        case .zenLedger:
            return "CoinCurrently-Portfolio-ZenLedger"
        }
    }
}

enum PortfolioExportBuilder {
    private struct ExportEntry {
        let date: Date
        let row: String
    }

    static func content(for format: PortfolioExportFormat, from portfolio: [Pie]) -> String? {
        switch format {
        case .csv:
            return csv(from: portfolio)
        case .json:
            return json(from: portfolio)
        case .plainText:
            return text(from: portfolio)
        case .koinly:
            return PortfolioTaxExportBuilder.koinlyCSV(from: portfolio)
        case .coinTracker:
            return PortfolioTaxExportBuilder.coinTrackerCSV(from: portfolio)
        case .tokenTax:
            return PortfolioTaxExportBuilder.tokenTaxCSV(from: portfolio)
        case .zenLedger:
            return PortfolioTaxExportBuilder.zenLedgerCSV(from: portfolio)
        }
    }

    static func csv(from portfolio: [Pie]) -> String {
        var rows = ["Date (UTC),Coin,Type,Amount,Price per coin,Fee,Value traded,Currency,Note,Address"]
        var entries: [ExportEntry] = []

        for pie in portfolio {
            let coin = pie.data?.symbol?.uppercased() ?? pie.data?.name ?? ""

            for transaction in pie.transactions {
                entries.append(ExportEntry(date: transaction.date, row: csvRow(coin: coin, transaction: transaction)))
            }

            for swap in pie.swaps {
                entries.append(ExportEntry(date: swap.date, row: csvSwapRow(swap: swap)))
            }

            for importEvent in pie.imports {
                entries.append(ExportEntry(date: importEvent.date, row: csvImportRow(coin: coin, importEvent: importEvent)))
            }
        }

        rows += entries
            .sorted { $0.date > $1.date }
            .map(\.row)

        return rows.joined(separator: "\n")
    }

    static func json(from portfolio: [Pie]) -> String? {
        let models = portfolio.compactMap(\.toPortfolioExportModel)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard
            let jsonData = try? encoder.encode(models),
            let jsonString = String(data: jsonData, encoding: .utf8)
        else {
            return nil
        }

        return jsonString
    }

    static func text(from portfolio: [Pie]) -> String? {
        let text = portfolio
            .map(textExportSection(for:))
            .joined()
            .trimmingCharacters(in: .newlines)

        guard !text.isEmpty else {
            return nil
        }

        return text
    }

    private static func csvField(_ value: String) -> String {
        value.replacingOccurrences(of: ",", with: ".")
    }

    private static func csvNumericField(_ value: Double?) -> String {
        guard let value else { return "" }
        return csvField(value.description)
    }

    private static func csvRow(coin: String, transaction: NewTransaction) -> String {
        let isTransfer = transaction.transactionType.isTransfer
        let value = (transaction.amount * (transaction.pricePerCoin ?? 0)) + transaction.fee

        return [
            transaction.date.portfolioExportDateTimeUTC,
            coin,
            transaction.transactionType.rawValue,
            csvField("\(transaction.amount)"),
            isTransfer ? "" : csvNumericField(transaction.pricePerCoin),
            isTransfer ? "" : csvNumericField(transaction.fee),
            isTransfer || value == 0 ? "" : csvNumericField(value),
            isTransfer ? "" : csvField(transaction.currency),
            csvField(transaction.note),
            csvField(transaction.address ?? "")
        ].joined(separator: ",")
    }

    private static func csvSwapRow(swap: NewSwapTransaction) -> String {
        let coin = "\(swap.fromCurrencySymbol.uppercased()) → \(swap.toCurrencySymbol.uppercased())"
        let value = (swap.fromAmount * swap.fromUnitPrice) + swap.fee

        return [
            swap.date.portfolioExportDateTimeUTC,
            coin,
            NewTransactionType.swap.rawValue,
            csvField("\(swap.fromAmount)"),
            csvNumericField(swap.fromUnitPrice),
            csvNumericField(swap.fee),
            value == 0 ? "" : csvNumericField(value),
            csvField(swap.selectedCurrency),
            csvField(swap.note),
            ""
        ].joined(separator: ",")
    }

    private static func csvImportRow(coin: String, importEvent: AddressImport) -> String {
        [
            importEvent.date.portfolioExportDateTimeUTC,
            coin,
            NewTransactionType.importAddress.rawValue,
            csvField(importEvent.balance),
            "",
            "",
            "",
            "",
            csvField(importEvent.walletName ?? ""),
            csvField(importEvent.address)
        ].joined(separator: ",")
    }

    private static func textExportSection(for pie: Pie) -> String {
        let coinName = pie.data?.name ?? pie.data?.symbol?.uppercased() ?? "Coin"
        var section = "• \(coinName)\n\n"

        let transactionsByType = Dictionary(grouping: pie.transactions, by: \.transactionType)

        for type in [NewTransactionType.buy, .sell, .transferIn, .transferOut] {
            guard let transactions = transactionsByType[type], !transactions.isEmpty else { continue }
            section += "-- \(type.rawValue) Transactions --\n"
            section += transactions
                .sorted { $0.date > $1.date }
                .map { textExportBlock(for: $0) }
                .joined()
        }

        if !pie.swaps.isEmpty {
            section += "-- Swap Transactions --\n"
            section += pie.swaps
                .sorted { $0.date > $1.date }
                .map(textExportBlock(for:))
                .joined()
        }

        if !pie.imports.isEmpty {
            section += "-- Wallet Imports --\n"
            section += pie.imports
                .sorted { $0.date > $1.date }
                .map(textExportBlock(for:))
                .joined()
        }

        return section
    }

    private static func textExportBlock(for transaction: NewTransaction) -> String {
        let selectedCurrency = CurrencyModel.allCurrencies.first {
            $0.code.lowercased() == transaction.currency.lowercased()
        }
        var block = "Date (UTC): \(transaction.date.portfolioExportDateTimeUTC)\n"
        block += "Amount: \(transaction.amount)\n"

        if !transaction.transactionType.isTransfer, let pricePerCoin = transaction.pricePerCoin {
            block += "Price per coin: \(pricePerCoin.formatted(style: .exact(currency: selectedCurrency)))\n"
        }

        if !transaction.transactionType.isTransfer, transaction.fee != 0 {
            block += "Fee: \(transaction.fee.formatted(style: .exact(currency: selectedCurrency)))\n"
        }

        let value = (transaction.amount * (transaction.pricePerCoin ?? 0)) + transaction.fee
        if !transaction.transactionType.isTransfer, value != 0 {
            block += "Value traded: \(value.formatted(style: .exact(currency: selectedCurrency)))\n"
        }

        if !transaction.transactionType.isTransfer {
            block += "Currency: \(transaction.currency)\n"
        }

        if !transaction.note.isEmpty {
            block += "Note: \(transaction.note)\n"
        }

        if let address = transaction.address, !address.isEmpty {
            block += "Address: \(address)\n"
        }

        return block + "\n"
    }

    private static func textExportBlock(for swap: NewSwapTransaction) -> String {
        let selectedCurrency = CurrencyModel.allCurrencies.first {
            $0.code.lowercased() == swap.selectedCurrency.lowercased()
        }
        var block = "Date (UTC): \(swap.date.portfolioExportDateTimeUTC)\n"
        block += "From: \(swap.fromAmount) \(swap.fromCurrencySymbol.uppercased()) @ \(swap.fromUnitPrice.formatted(style: .exact(currency: selectedCurrency)))\n"
        block += "To: \(swap.toAmount) \(swap.toCurrencySymbol.uppercased()) @ \(swap.toUnitPrice.formatted(style: .exact(currency: selectedCurrency)))\n"

        if swap.fee != 0 {
            block += "Fee: \(swap.fee.formatted(style: .exact(currency: selectedCurrency)))\n"
        }

        if !swap.note.isEmpty {
            block += "Note: \(swap.note)\n"
        }

        return block + "\n"
    }

    private static func textExportBlock(for importEvent: AddressImport) -> String {
        var block = "Date (UTC): \(importEvent.date.portfolioExportDateTimeUTC)\n"

        if let walletName = importEvent.walletName, !walletName.isEmpty {
            block += "Wallet: \(walletName)\n"
        }

        block += "Address: \(importEvent.address)\n"
        block += "Balance: \(importEvent.balance)\n"
        return block + "\n"
    }
}
