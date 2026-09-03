//
//  CryptoDetailWidgetViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-09-12.
//

import Foundation

@MainActor
@Observable
final class CryptoDetailWidgetViewModel {
    var widgetCurrencies = [Toplist]()
    var cryptoInfo: CurrencyDataModel?

    private let cryptoDetailRepository: CryptoDetailRepository

    init(
        cryptoInfo: CurrencyDataModel?,
        cryptoDetailRepository: CryptoDetailRepository = CryptoDetailRepositoryImp.shared
    ) {
        self.cryptoInfo = cryptoInfo
        self.cryptoDetailRepository = cryptoDetailRepository
    }

    func load() async {
        widgetCurrencies = await cryptoDetailRepository.widgetCurrencies
    }

    func addCurrencyToWidgets() async {
        guard let cryptoInfo else { return }

        let toplistItem = cryptoInfo.toToplist()

        widgetCurrencies.append(toplistItem)
        await cryptoDetailRepository.addCurrencyToWidget(toplist: toplistItem)
    }

    func replaceWidgetCurrency(coin: Toplist, with: Toplist? = nil) async {
        guard let cryptoInfo, let index = widgetCurrencies.firstIndex(where: { $0.id == coin.id }) else { return }

        let toplistItem = with ?? cryptoInfo.toToplist()

        widgetCurrencies[index] = toplistItem
        await cryptoDetailRepository.replacedWidget(at: index, toplist: toplistItem)
    }
}
