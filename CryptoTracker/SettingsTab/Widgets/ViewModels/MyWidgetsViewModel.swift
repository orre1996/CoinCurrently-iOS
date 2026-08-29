//
//  MyWidgetsViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-20.
//

import Foundation

@MainActor
protocol MyWidgetsViewModel: ObservableObject {
    var widgetCurrencies: [Toplist] { get set }

    func widgetCurrenciesChangedOrder(newOrder: [Toplist]) async
    func deleteCoin(coin: Toplist) async
}

@MainActor @Observable
final class MyWidgetsViewModelImp: MyWidgetsViewModel {
     var widgetCurrencies = [Toplist]()

    var cryptoDetailRepository: CryptoDetailRepositoryImp

    init(
        cryptoDetailRepository: CryptoDetailRepositoryImp = CryptoDetailRepositoryImp.shared
    ) {
        self.cryptoDetailRepository = cryptoDetailRepository
    }
    
    func setStartData() async {
        await cryptoDetailRepository.ensureCacheLoaded()
        widgetCurrencies = await cryptoDetailRepository.widgetCurrencies
    }

    func widgetCurrenciesChangedOrder(newOrder: [Toplist]) async {
        await cryptoDetailRepository.widgetCurrenciesChangedOrder(newOrder: newOrder)
    }
    
    func deleteCoin(coin: Toplist) async {
        widgetCurrencies = await cryptoDetailRepository.removeWidgetCoin(coin: coin)
    }
}
