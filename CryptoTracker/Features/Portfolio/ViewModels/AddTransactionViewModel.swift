//
//  AddTransactionViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-08-30.
//

import SwiftUI
import Combine

@MainActor
protocol AddTransactionViewModel {
    var transactionType: PortfolioTransactionType { get }
    var currencyDetail: CurrencyDataModel? { get set }
    var pie: PortfolioModel? { get }
    var allTransactions: [PortfolioTransaction]? { get }
    var transaction: PortfolioTransaction? { get }
    var containsCoin: Bool { get }
    var selectedCurrency: CurrencyModel { get set }
    var address: String { get set }
    var amount: Double? { get set }
    var averageCost: Double? { get set }
    var fees: Double? { get set }
    var date: Date { get set }
    var note: String { get set }
    var dateRange: ClosedRange<Date> { get }
    var canImport: Bool { get }
    var currentPrice: Double { get }
    var getEditValue: Double { get }
    var isInputValid: Bool { get }

    func setStartData() async
    func getCryptoDetail() async
    func addTransaction() async
}

@MainActor @Observable
final class AddTransactionViewModelImp: AddTransactionViewModel {
    let transactionType: PortfolioTransactionType
    var currencyDetail: CurrencyDataModel?
    var pie: PortfolioModel?
    var allTransactions: [PortfolioTransaction]?
    var transaction: PortfolioTransaction?

    var containsCoin: Bool = false
    var selectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()

    // Input fields
    var address: String = ""
    var amount: Double? = nil
    var averageCost: Double? = nil
    var fees: Double? = nil
    var date: Date = Date()
    var note: String = ""
    var dateRange: ClosedRange<Date> = Date() ... Date()
    
    private var cancellable: Set<AnyCancellable> = []

    private let cryptoDetailRepository: CryptoDetailRepository
    private let portfolioRepository: PortfolioRepository
    private let storeKitManager: StoreKitManager
    
    init(
        transactionType: PortfolioTransactionType,
        currencyDetail: CurrencyDataModel?,
        transaction: PortfolioTransaction?,
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared,
        portfolioRepository: PortfolioRepository = PortfolioRepositoryImp.shared,
        storeKitManager: StoreKitManager = StoreKitManagerImp.shared
    ) {
        self.cryptoDetailRepository = cryptoDetailRepository
        self.portfolioRepository = portfolioRepository
        self.storeKitManager = storeKitManager

        self.transactionType = transactionType
        self.currencyDetail = currencyDetail
        
        self.transaction = transaction
        self.selectedCurrency = CurrencyModel.allCurrencies.first(where: { $0.code == transaction?.currency ?? selectedCurrency.code }) ?? selectedCurrency
        
        self.address = transaction?.address ?? ""
        self.amount = transaction?.amount
        self.averageCost = transaction?.pricePerCoin
        self.fees = transaction?.fee
        self.date = transaction?.date ?? Date()
        self.note = transaction?.note ?? ""
        self.setDate()
    }
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await portfolioRepository.ensureCacheLoaded()
        
        self.pie = await portfolioRepository.portfolioModels.first(where: { $0.id == currencyDetail?.id })
        self.allTransactions = await portfolioRepository.portfolioModels.getAllTransactions(of: currencyDetail?.id)
        self.containsCoin = await portfolioRepository.portfolioModels.contains(where: { $0.id == currencyDetail?.id ?? "" })
    }
    
    var canImport: Bool {
        guard let symbol = currencyDetail?.symbol?.lowercased() else { return false }

        let platformId = currencyDetail?.asset_platform_id ?? ""
        let array = ["btc", "dash", "doge", "ltc", "eth"]

        return array.contains(symbol) || platformId == "ethereum"
    }
    
    var currentPrice: Double {
        return currencyDetail?.market_data?.current_price?.getConvertedCurrency(selectedCurrency: selectedCurrency.code) ?? 0
    }
    
    var getEditValue: Double {
        guard
            let buyTransaction = allTransactions?.ofType(.buy).contains(where: { $0.id == transaction?.id }),
            let inTransfer = allTransactions?.ofType(.transferIn).contains(where: { $0.id == transaction?.id }),
            let transaction
        else {
            return 0
        }
        
        return buyTransaction || inTransfer ? -transaction.amount : transaction.amount
    }
    var isInputValid: Bool {
        let isInputValid = (amount ?? 0) > 0
        let isNotesValid = note.count <= 200

        if transactionType == .importAddress {
            return !address.isEmpty && isNotesValid
        } else {
            return isInputValid && isNotesValid
        }
    }
    
    func getCryptoDetail() async {
        if let cryptoData = await cryptoDetailRepository.getCurrencyDetails(id: currencyDetail?.id) {
            self.currencyDetail = cryptoData
        }
    }
    
    private func setDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let tempDate = dateFormatter.date(from: currencyDetail?.genesis_date ?? "2009-01-03")
        
        dateRange = (tempDate ?? Date().setTime(year: 2009, month: 01, day: 03) ?? Date())...Date()
    }
    
    func addTransaction() async {
        guard let amount else {
            return
        }
        
        let isNewTransaction = transaction == nil

        await portfolioRepository.ensureCacheLoaded()
        let previousTransactionCount = await portfolioRepository.cachedPortfolioPies?.data.allTransactionsCount ?? 0
        
        let newTransaction = PortfolioTransaction(
            date: date,
            amount: amount,
            pricePerCoin: transactionType.isTransfer ? nil : averageCost == nil ? currentPrice : averageCost ?? 0,
            fee: fees ?? 0,
            note: note,
            transactionType: transactionType,
            currency: selectedCurrency.code
        )
        
        if let transaction {
            await editTransaction(oldId: transaction.id, transaction: newTransaction)
        } else {
            await addTransaction(transaction: newTransaction)
        }
        
        if isNewTransaction {
            AnalyticsManager.shared.log(
                TransactionAdded(
                    fromScreen: .newPortfolioTransaction,
                    coinName: currencyDetail?.name ?? ""
                )
            )
        } else {
            AnalyticsManager.shared.log(
                TransactionEdited(
                    fromScreen: .newPortfolioTransaction,
                    coinName: currencyDetail?.name ?? ""
                )
            )
        }
        
        NotificationCenter.default.post(
            Notification(
                name: .newTransaction,
                object: nil,
                userInfo: [
                    "transaction": newTransaction.id.uuidString,
                    "previousTransactionCount": isNewTransaction ? previousTransactionCount : -1
                ]
            )
        )
        NotificationCenter.default.post(Notification(name: .showRatingView, object: nil, userInfo: [:]))
    }
    
    private func addTransaction(transaction: PortfolioTransaction) async {
        guard let currencyDetail, let id = currencyDetail.id else {
            return
        }

        guard pie == nil else {
            await portfolioRepository.addNewTransaction(
                id: id,
                event: transaction
            )
            
            return
        }
        
        await portfolioRepository.addNewCoin(
            coin: currencyDetail.toToplist(),
            event: transaction,
            allCurrencies: currencyDetail.market_data?.current_price,
        )
    }
    
    private func editTransaction(oldId: UUID?, transaction: PortfolioTransaction) async {
        await addTransaction(transaction: transaction)
        _ = await portfolioRepository.deleteTransaction(
            id: currencyDetail?.id ?? "",
            uuid: oldId
        )
    }
}
