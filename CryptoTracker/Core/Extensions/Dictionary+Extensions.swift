//
//  Dictionary+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 5/22/25.
//

import Foundation

extension Dictionary where Key == String, Value == Double {
    func getConvertedCurrency(selectedCurrency: String = (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code) -> Double? {
        return self[selectedCurrency.lowercased()]
    }
}

extension Dictionary where Key == String, Value == String {
    func getConvertedCurrency(selectedCurrency: String = (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code) -> String? {
        return self[selectedCurrency.lowercased()]
    }
}

