//
//  PortfolioCurrencyModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-06-20.
//

import Foundation

struct PortfolioCurrencyModel: Codable {
    var id: String?
    var amount: Double?
    var entryCost: Double?
    var currency: String?
    var buyTransactions: [Transaction] = []
    var sellTransactions: [Transaction] = []
    var inTransferTransactions: [Transaction] = []
    var outTransferTransactions: [Transaction] = []
    var importTransactions: [Transaction] = []
    
    /*func toCleanPortfolioModel(name: String) -> CleanPortfolioModel {
        return CleanPortfolioModel(
            name: name,
            buyTransactions: buyTransactions.map({ $0.toCleanTransaction(isTransferType: false) }),
            sellTransactions: sellTransactions.map({ $0.toCleanTransaction(isTransferType: false) }),
            depositTransactions: inTransferTransactions.map({ $0.toCleanTransaction(isTransferType: true) }),
            withdrawalTransactions: outTransferTransactions.map({ $0.toCleanTransaction(isTransferType: true) }),
            importTransactions: importTransactions.map({ $0.toCleanTransaction(isTransferType: false) })
        )
    }*/
    
    /*func getCurrentAmount() -> Double {
        let importAmount = importTransactions.map({ $0.amount }).reduce(0, +)
        let buyAmount = buyTransactions.map({ $0.amount }).reduce(0, +)
        let inTransactions = inTransferTransactions.map({ $0.amount }).reduce(0, +)
        let sellAmount = sellTransactions.map({ $0.amount }).reduce(0, +)
        let outTransactions = outTransferTransactions.map({ $0.amount }).reduce(0, +)
        return (amount ?? 0) + importAmount + buyAmount + inTransactions - sellAmount - outTransactions
    }
    
    var allTransactions: [Transaction] {
        return buyTransactions + sellTransactions + inTransferTransactions + outTransferTransactions + importTransactions
    }*/
}

struct CleanPortfolioModel: Codable {
    var name: String?
    var buyTransactions: [CleanTransactionModel]? = []
    var sellTransactions: [CleanTransactionModel]? = []
    var depositTransactions: [CleanTransactionModel]? = []
    var withdrawalTransactions: [CleanTransactionModel]? = []
    var importTransactions: [CleanTransactionModel]? = []
}

extension PortfolioCurrencyModel {
    func migrateToNewPortfolioModel() -> NewPortfolioModel {
        var transactions = [NewTransaction]()
        var imports = [AddressImport]()
        
        if let amount = amount {
            transactions.append(
                NewTransaction(
                    amount: amount,
                    pricePerCoin: entryCost,
                    fee: 0.0,
                    note: "",
                    transactionType: .buy,
                    currency: currency ?? (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code
                )
            )
        }
        
        buyTransactions.forEach {
            transactions.append(
                NewTransaction(
                    amount: $0.amount,
                    pricePerCoin: $0.pricePerCoin,
                    fee: $0.fee ?? 0,
                    note: $0.note ?? "",
                    transactionType: .buy,
                    currency: $0.currency ?? (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code
                )
            )
        }
        
        sellTransactions.forEach {
            transactions.append(
                NewTransaction(
                    amount: $0.amount,
                    pricePerCoin: $0.pricePerCoin,
                    fee: $0.fee ?? 0,
                    note: $0.note ?? "",
                    transactionType: .sell,
                    currency: $0.currency ?? (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code
                )
            )
        }
        
        inTransferTransactions.forEach {
            transactions.append(
                NewTransaction(
                    amount: $0.amount,
                    pricePerCoin: $0.pricePerCoin,
                    fee: $0.fee ?? 0,
                    note: $0.note ?? "",
                    transactionType: .transferIn,
                    currency: $0.currency ?? (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code
                )
            )
        }
        
        outTransferTransactions.forEach {
            transactions.append(
                NewTransaction(
                    amount: $0.amount,
                    pricePerCoin: $0.pricePerCoin,
                    fee: $0.fee ?? 0,
                    note: $0.note ?? "",
                    transactionType: .transferOut,
                    currency: $0.currency ?? (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code
                )
            )
        }
        
        importTransactions.forEach {
            imports.append(
                AddressImport(
                    coinId: id,
                    address: $0.address ?? "",
                    balance: "\($0.amount)",
                    tokenInfos: [],
                    blockChain: Chain(rawValue: id ?? "") ?? .token
                )
            )
        }
        
        return NewPortfolioModel(
            id: id ?? "",
            transactions: transactions,
            swaps: [],
            imports: imports
        )
    }
}

struct Transaction: Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var amount: Double
    var pricePerCoin: Double?
    var fee: Double?
    var note: String?
    var transferType: Int = 0
    var address: String? = nil
    var currency: String? = (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code
    
    func getProfitPercent(currentPrice: Double?) -> Double? {
        if pricePerCoin == nil { return nil }
        
        let originalCost = amount * (pricePerCoin ?? 1)
        
        let currentValue = amount * (currentPrice ?? 0)
        return (currentValue / originalCost - 1) * 100
    }
    
    func getProfitValue(currentPrice: Double?) -> Double? {
        guard let pricePerCoin else {
            return nil
        }
        
        let profitPercent = getProfitPercent(currentPrice: currentPrice) ?? 0
        return ((profitPercent / 100)) * (pricePerCoin) * amount
    }
    
    func toCleanTransaction(isTransferType: Bool) -> CleanTransactionModel {
        let selectedCurrency = CurrencyModel.allCurrencies.first(where: { $0.code.lowercased() == currency?.lowercased() })
        let value = (amount * (pricePerCoin ?? 0)) + (fee ?? 0)
        
        return CleanTransactionModel(
            date: date.longDateTime,
            amount: "\(amount)",
            pricePerCoin: isTransferType ? nil : pricePerCoin?.formatted(style: .exact(currency: selectedCurrency)),
            fee: isTransferType ? nil : fee?.formatted(style: .exact(currency: selectedCurrency)),
            valueTraded:  isTransferType ? nil : value == 0 ? nil : value.formatted(style: .exact(currency: selectedCurrency)),
            currency: isTransferType ? nil : currency,
            note: note?.isEmpty ?? true ? nil : note
        )
    }
    
    func getFee(transactionType: TransactionType) -> Double {
        return 0.0
        /*let fee = fee ?? 0
        let addAddTransaction = transactions.filter { $0.transactionType == .buy || $0.transactionType == .importAddress }
        return addAddTransaction ? fee : -fee*/
    }
    
    func getTotalSpent(transactionType: TransactionType) -> Double {
        return 0.0
        /*let fee = getFee(transactionType: transactionType)
        return (pricePerCoin ?? 0) + fee*/
    }
}
