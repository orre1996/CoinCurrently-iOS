//
//  CryptoEntry.swift
//  Cryptocurrently
//
//  Created by Oscar Berggren on 2020-11-06.
//

import Foundation
import WidgetKit
import SwiftUI

struct CryptoEntry: TimelineEntry {
    let date: Date = Date()
    let cryptoInfos: [Toplist]
    let currencyLogos: [UIImage]
    let selectedCurrency: CurrencyModel
    let selectedCoinIDs: [String]
    let isPlaceholder: Bool
    
    func copyWithPlaceholder() -> CryptoEntry {
        return CryptoEntry(
            cryptoInfos: cryptoInfos,
            currencyLogos: currencyLogos,
            selectedCurrency: selectedCurrency,
            selectedCoinIDs: selectedCoinIDs,
            isPlaceholder: true
        )
    }
    
    static func empty(selectedCoinIDs: [String] = []) -> CryptoEntry {
        return CryptoEntry(
            cryptoInfos: [],
            currencyLogos: [],
            selectedCurrency: SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel(),
            selectedCoinIDs: selectedCoinIDs,
            isPlaceholder: false
        )
    }
}
