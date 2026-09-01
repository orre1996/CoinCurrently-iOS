//
//  CalculatorViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-20.
//

import Foundation
import Combine

@MainActor
protocol CalculatorViewModel: ObservableObject {
    var calculatorList: [Toplist]? { get }
    var calculatorPrices: [Cryptocurrency]? { get }
    var input: String { get set }
    var selectedCurrency: CurrencyModel { get set }

    func getCalculatorPrices() async
    func getAmount(for id: String?, input inputValue: String, currency: CurrencyModel) -> Double?
}

@MainActor @Observable
final class CalculatorViewModelImp: CalculatorViewModel {
    private let toplistRepository: ToplistRepository
    private let calculatorRepository: CalculatorRepository

    var calculatorList: [Toplist]?
    var calculatorPrices: [Cryptocurrency]?
    var input: String = "1000"
    var selectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    
    init(
        toplistRepository: ToplistRepository = ToplistRepositoryImp.shared,
        calculatorRepository: CalculatorRepository = CalculatorRepositoryImp.shared
    ) {
        self.toplistRepository = toplistRepository
        self.calculatorRepository = calculatorRepository
    }
    
    func setStartData() async {
        await calculatorRepository.ensureCacheLoaded()
        await toplistRepository.ensureCacheLoaded()
        
        if let prices = await calculatorRepository.cachedPrices?.data {
            self.calculatorPrices = prices
        }
        
        if let toplist = await toplistRepository.cachedSmallToplist?.data, !toplist.isEmpty {
            self.calculatorList = toplist.sorted(by: { $0.market_cap_rank ?? 9999 < $1.market_cap_rank ?? 9999 })
        }
    }

    func getCalculatorPrices() async {
        if let smallToplist = await toplistRepository.getSmallToplist() {
            calculatorList = smallToplist.sorted(by: { $0.market_cap_rank ?? 9999 < $1.market_cap_rank ?? 9999 })
            await getFilteredToplist()
        }
    }

    func getAmount(for id: String?, input inputValue: String, currency: CurrencyModel) -> Double? {
        guard let calculatorPrices, let coinPrices = calculatorPrices.first(where: { $0.id == id })?.prices else {
            return nil
        }

        let amount = Double(inputValue) ?? 0.0
        return Double(amount / (coinPrices[currency.code.lowercased()] ?? 0))
    }

    private func getFilteredToplist() async {
        guard let ids = calculatorList?.compactMap({ $0.id }) else {
            return
        }

        if let prices = await calculatorRepository.getCalculatorPrices(ids: ids) {
            calculatorPrices = prices
        }
    }
}
