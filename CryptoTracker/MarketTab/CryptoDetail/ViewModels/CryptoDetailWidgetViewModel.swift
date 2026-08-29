//
//  CryptoDetailWidgetViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-09-12.
//

import SwiftUI

@MainActor
protocol CryptoDetailWidgetViewModel: ObservableObject {
    var widgetCurrencies: [Toplist] { get set }
    var cryptoInfo: CurrencyDataModel? { get }
    var justAddedToWidget: Bool { get }

    func addCurrencyToWidgets() async
    func replaceWidgetCurrency(at index: Int) async
    func widgetCurrenciesChangedOrder(newOrder: [Toplist]) async
}

@MainActor
final class CryptoDetailWidgetViewModelImp: CryptoDetailWidgetViewModel {
    @Published var widgetCurrencies = [Toplist]()
    
    @Published private(set) var cryptoInfo: CurrencyDataModel?
    @Published private(set) var justAddedToWidget: Bool = false

    private let cryptoDetailRepository: CryptoDetailRepository

    init(cryptoInfo: CurrencyDataModel?,
         cryptoDetailRepository: CryptoDetailRepositoryImp = CryptoDetailRepositoryImp.shared) {
        self.cryptoInfo = cryptoInfo
        self.cryptoDetailRepository = cryptoDetailRepository
        // self.widgetCurrencies = cryptoDetailRepository.widgetCurrencies

       /* if self.widgetCurrencies.count < 8 {
            self.addCurrencyToWidgets()
            self.justAddedToWidget = true
        }*/
    }
    
    func addCurrencyToWidgets() async {
        guard let cryptoInfo else { return }

        let toplistItem = cryptoInfo.toToplist()

        widgetCurrencies.append(toplistItem)
        await cryptoDetailRepository.addCurrencyToWidget(toplist: toplistItem)
    }
    
    func replaceWidgetCurrency(at index: Int) async {
        guard let cryptoInfo else { return }
        
        let toplistItem = cryptoInfo.toToplist()
        
        widgetCurrencies[index] = toplistItem
        await cryptoDetailRepository.replacedWidget(at: index, toplist: toplistItem)
    }
    
    func widgetCurrenciesChangedOrder(newOrder: [Toplist]) async {
        await cryptoDetailRepository.widgetCurrenciesChangedOrder(newOrder: newOrder)
    }
}
