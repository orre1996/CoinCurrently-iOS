//
//  CleanTransactionModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 9/24/25.
//

import SwiftUI

struct CleanTransactionModel: Codable {
    var date: String
    var amount: String
    var pricePerCoin: String?
    var fee: String?
    var valueTraded: String?
    var currency: String? = (SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()).code
    var note: String?
}
