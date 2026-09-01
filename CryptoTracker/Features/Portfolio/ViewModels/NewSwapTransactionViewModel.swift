//
//  NewTransactionViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-08-30.
//

import SwiftUI
import Combine

@MainActor
protocol NewSwapTransactionViewModel {
    var transactionType: NewTransactionType { get }
    var currencyDetail: CurrencyDataModel? { get set }
    var transaction: NewSwapTransaction? { get }
    var containsCoin: Bool { get }
    var selectedCurrency: CurrencyModel { get set }
    var toInformation: (String, String) { get set }
    var fromAmount: Double? { get set }
    var fromAverageCost: Double? { get set }
    var toAmount: Double? { get set }
    var fees: Double? { get set }
    var date: Date { get set }
    var note: String { get set }
    var dateRange: ClosedRange<Date> { get }
    var currentPrice: Double { get }
    var getFromEditValue: Double { get }
    var isInputValid: Bool { get }

    func setStartData() async
    func getCryptoDetail() async
    func addTransaction() async
}

@MainActor @Observable
final class NewSwapTransactionViewModelImp: NewSwapTransactionViewModel {
    let transactionType: NewTransactionType
    var currencyDetail: CurrencyDataModel?
    var transaction: NewSwapTransaction?
    var containsCoin: Bool = false
    var selectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    var toInformation: (String, String)
    
    // Input fields
    var fromAmount: Double? = nil
    var fromAverageCost: Double? = nil
    var toAmount: Double? = nil
    var fees: Double? = nil
    var date: Date = Date()
    var note: String = ""
    var dateRange: ClosedRange<Date> = Date() ... Date()
    
    private var portfolioModels: [NewPortfolioModel] = []
    
    private var cancellable: Set<AnyCancellable> = []

    private let cryptoDetailRepository: CryptoDetailRepository
    private let portfolioRepository: PortfolioRepository
    private let storeKitManager: StoreKitManager
    
    init(
        transactionType: NewTransactionType,
        currencyDetail: CurrencyDataModel?,
        transaction: NewSwapTransaction?,
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

        toInformation = transaction != nil ? (transaction?.toCurrencyId ?? "bitcoin", transaction?.toCurrencySymbol ?? "BTC") : currencyDetail?.id == "bitcoin" ? ("ethereum", "ETH") :  ("bitcoin", "BTC")
        
        self.selectedCurrency = CurrencyModel.allCurrencies.first(where: { $0.code == transaction?.selectedCurrency ?? selectedCurrency.code }) ?? selectedCurrency

        self.fromAmount = transaction?.fromAmount
        self.fromAverageCost = transaction?.fromUnitPrice
        self.toAmount = transaction?.toAmount
        self.fees = transaction?.fee
        self.date = transaction?.date ?? Date()
        self.note = transaction?.note ?? ""
        self.setDate()
    }
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        await portfolioRepository.ensureCacheLoaded()
        
        portfolioModels = await portfolioRepository.portfolioModels
    }
    
    var currentPrice: Double {
        return currencyDetail?.market_data?.current_price?.getConvertedCurrency(selectedCurrency: selectedCurrency.code) ?? 0
    }
    
    var getFromEditValue: Double {
        return transaction?.fromAmount ?? 0
    }

    var isInputValid: Bool {
        let isInputValid = (fromAmount ?? 0) > 0 && (toAmount ?? 0) > 0
        let isNotesValid = note.count <= 200

        return isInputValid && isNotesValid
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
        guard let fromAmount, let toAmount else {
            return
        }
        
        let isNewTransaction = transaction == nil

        await portfolioRepository.ensureCacheLoaded()
        let previousTransactionCount = await portfolioRepository.cachedPortfolioPies?.data.allTransactionsCount ?? 0
        
        let newTransaction = NewSwapTransaction(
            selectedCurrency: selectedCurrency.code,
            fromCurrencyId: currencyDetail?.id ?? "",
            fromCurrencySymbol: currencyDetail?.symbol ?? "",
            fromAmount: fromAmount,
            fromUnitPrice: fromAverageCost ?? currentPrice,
            toCurrencyId: toInformation.0,
            toCurrencySymbol: toInformation.1.lowercased(),
            toAmount: toAmount,
            toUnitPrice: (currentPrice * fromAmount) / toAmount,
            fee: fees ?? 0,
            note: note
        )

        if let transaction {
            await editTransaction(oldId: transaction.id, transaction: newTransaction)
        } else {
            await addTransaction(transaction: newTransaction)
        }

        if isNewTransaction {
            AnalyticsManager.shared.log(
                TransactionAdded(
                    fromScreen: .newSwapTransaction,
                    coinName: currencyDetail?.name ?? ""
                )
            )
        } else {
            AnalyticsManager.shared.log(
                TransactionEdited(
                    fromScreen: .newSwapTransaction,
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
    
    private func addTransaction(transaction: NewSwapTransaction) async {
        guard await portfolioRepository.portfolioModels.first(where: { $0.id == toInformation.0 }) == nil else {
            await portfolioRepository.addNewTransaction(
                id: toInformation.0,
                event: transaction
            )
            
            return
        }
        
        let cryptoInfo = await cryptoDetailRepository.getCurrencyDetails(id: toInformation.0)
        
        await portfolioRepository.addNewCoin(
            coin: cryptoInfo?.toToplist() ?? Toplist(id: toInformation.0),
            event: transaction,
            allCurrencies: cryptoInfo?.market_data?.current_price,
        )
    }
    
    private func editTransaction(oldId: UUID?, transaction: NewSwapTransaction) async {
        await addTransaction(transaction: transaction)
        _ = await portfolioRepository.deleteTransaction(
            id: self.transaction?.toCurrencyId ?? toInformation.0,
            uuid: oldId
        )
    }
}
