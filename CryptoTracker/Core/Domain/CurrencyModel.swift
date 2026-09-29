//
//  CurrencyModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-01-24.
//

import Foundation

public struct CurrencyModel: Codable, Equatable, Hashable, Sendable {
    var currency: String = "United States dollar"
    var code: String = "USD"
    var symbol: String = "$"
    var locale: String = "en_US"
    var suffix: Bool = false
    var voiceOverName: String? = "dollars"
    
    /// Spoken currency name for VoiceOver (e.g. "dollars", "crowns"). Falls back to `allCurrencies` lookup, then `currency`.
    var voiceOverCurrencyName: String {
        if let voiceOverName = voiceOverName?.trimmingCharacters(in: .whitespaces), !voiceOverName.isEmpty {
            return voiceOverName
        }
        
        if let knownCurrency = Self.allCurrencies.first(where: { $0.code == code }),
           let knownName = knownCurrency.voiceOverName?.trimmingCharacters(in: .whitespaces),
           !knownName.isEmpty {
            return knownName
        }
        
        let name = currency.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return "" }
        let pluralSuffix = locale.isEmpty ? "" : "s"
        return "\(name)\(pluralSuffix)"
    }

    /// Fiat name in the in-app language. Crypto names stay as written.
    var localizedName: String {
        #if IS_APP
        guard Localization.locale.language.languageCode?.identifier != "en",
              code.count == 3,
              code.allSatisfy(\.isLetter),
              let name = Localization.locale.localizedString(forCurrencyCode: code)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty
        else {
            return currency
        }
        return name
        #else
        return currency
        #endif
    }
    
    static var ´default´: CurrencyModel {
        CurrencyModel()
    }
    
    static var empty: CurrencyModel {
        CurrencyModel(currency: "", code: "", symbol: "", locale: "", suffix: false, voiceOverName: nil)
    }
    
    static let allCurrencies = [
        CurrencyModel(currency: "Emirati dirham", code: "AED", symbol: "د.إ", locale: "ar_AE", suffix: true, voiceOverName: "dirhams"),
        CurrencyModel(currency: "Australian dollar", code: "AUD", symbol: "$", locale: "en_AU", voiceOverName: "dollars"),
        CurrencyModel(currency: "Bitcoin cash", code: "BCH", symbol: "Ƀ", locale: "en_US", voiceOverName: "bitcoin cash"),
        CurrencyModel(currency: "Bitcoin", code: "BTC", symbol: "₿", locale: "en_US", voiceOverName: "bitcoin"),
        CurrencyModel(currency: "Bit", code: "BITS", symbol: "₿", locale: "en_US", voiceOverName: "bits"),
        CurrencyModel(currency: "Binance coin", code: "BNB", symbol: "BNB", locale: "en_US", suffix: true, voiceOverName: "binance coins"),
        CurrencyModel(currency: "Brazilian real", code: "BRL", symbol: "R$", locale: "pt_BR", voiceOverName: "reais"),
        CurrencyModel(currency: "Canadian dollar", code: "CAD", symbol: "$", locale: "en_CA", voiceOverName: "dollars"),
        CurrencyModel(currency: "Swiss franc", code: "CHF", symbol: "CHF", locale: "gsw_CH", suffix: true, voiceOverName: "francs"),
        CurrencyModel(currency: "Chilean peso", code: "CLP", symbol: "$", locale: "es_CL", voiceOverName: "pesos"),
        CurrencyModel(currency: "Chinese yuan", code: "CNY", symbol: "¥", locale: "zh_Hant_HK", voiceOverName: "yuan"),
        CurrencyModel(currency: "Czech koruna", code: "CZK", symbol: "Kč", locale: "cs_CZ", suffix: true, voiceOverName: "korunas"),
        CurrencyModel(currency: "Danish krone", code: "DKK", symbol: "kr", locale: "da_DK", suffix: true, voiceOverName: "crowns"),
        CurrencyModel(currency: "Polkadot", code: "DOT", symbol: "DOT", locale: "en_EU", suffix: true, voiceOverName: "polkadot"),
        CurrencyModel(currency: "Ethereum", code: "ETH", symbol: "Ξ", locale: "en_US", voiceOverName: "ether"),
        CurrencyModel(currency: "EOS", code: "EOS", symbol: "EOS", locale: "en_US", suffix: true, voiceOverName: "EOS"),
        CurrencyModel(currency: "Euro", code: "EUR", symbol: "€", locale: "en_EU", voiceOverName: "euros"),
        CurrencyModel(currency: "British pound sterling", code: "GBP", symbol: "£", locale: "en_IE", voiceOverName: "pounds"),
        CurrencyModel(currency: "Hong Kong dollar", code: "HKD", symbol: "$", locale: "en_HK", voiceOverName: "dollars"),
        CurrencyModel(currency: "Hungarian forint", code: "HUF", symbol: "ft", locale: "zh_Hant_HK", voiceOverName: "forints"),
        CurrencyModel(currency: "Indonesian rupiah", code: "IDR", symbol: "Rp", locale: "id_ID", voiceOverName: "rupiah"),
        CurrencyModel(currency: "Israeli shekel", code: "ILS", symbol: "₪", locale: "he_IL", voiceOverName: "shekels"),
        CurrencyModel(currency: "Indian rupee", code: "INR", symbol: "₹", locale: "en_IN", voiceOverName: "rupees"),
        CurrencyModel(currency: "Japanese yen", code: "JPY", symbol: "¥", locale: "ja_JP", voiceOverName: "yen"),
        CurrencyModel(currency: "South Korean won", code: "KRW", symbol: "₩", locale: "ko_KR", voiceOverName: "won"),
        CurrencyModel(currency: "Sri Lankan rupee", code: "LKR", symbol: "Rs", locale: "si_LK", voiceOverName: "rupees"),
        CurrencyModel(currency: "Chainlink", code: "LINK", symbol: "LINK", locale: "en_US", suffix: true, voiceOverName: "chainlink"),
        CurrencyModel(currency: "Litecoin", code: "LTC", symbol: "Ł", locale: "en_US", voiceOverName: "litecoin"),
        CurrencyModel(currency: "Mexican peso", code: "MXN", symbol: "$", locale: "es_MX", voiceOverName: "pesos"),
        CurrencyModel(currency: "Malaysian ringgit", code: "MYR", symbol: "RM", locale: "ms_MY", voiceOverName: "ringgit"),
        CurrencyModel(currency: "Norwegian krone", code: "NOK", symbol: "kr", locale: "nn_NO", suffix: true, voiceOverName: "crowns"),
        CurrencyModel(currency: "New Zealand dollar", code: "NZD", symbol: "$", locale: "en_NZ", voiceOverName: "dollars"),
        CurrencyModel(currency: "Philippine peso", code: "PHP", symbol: "₱", locale: "fil_PH", voiceOverName: "pesos"),
        CurrencyModel(currency: "Pakistani rupee", code: "PKR", symbol: "Rs", locale: "pa_Arab_PK", voiceOverName: "rupees"),
        CurrencyModel(currency: "Złoty", code: "PLN", symbol: "zł", locale: "pl_PL", suffix: true, voiceOverName: "zloty"),
        CurrencyModel(currency: "Russian ruble", code: "RUB", symbol: "₽", locale: "ru_RU", suffix: true, voiceOverName: "rubles"),
        CurrencyModel(currency: "Swedish krona", code: "SEK", symbol: "kr", locale: "sv_SE", suffix: true, voiceOverName: "crowns"),
        CurrencyModel(currency: "Satoshi", code: "SATS", symbol: "sats", locale: "en_US", suffix: true, voiceOverName: "satoshis"),
        CurrencyModel(currency: "Singapore dollar", code: "SGD", symbol: "$", locale: "zh_Hans_SG", voiceOverName: "dollars"),
        CurrencyModel(currency: "Thai baht", code: "THB", symbol: "฿", locale: "th_TH", voiceOverName: "baht"),
        CurrencyModel(currency: "Turkish lira", code: "TRY", symbol: "₺", locale: "tr_TR", voiceOverName: "lira"),
        CurrencyModel(currency: "Ukrainian hryvna", code: "UAH", symbol: "₴", locale: "uk_UA", suffix: true, voiceOverName: "hryvnas"),
        CurrencyModel(currency: "United States dollar", code: "USD", symbol: "$", locale: "en_US", voiceOverName: "dollars"),
        CurrencyModel(currency: "Vietnamese dong", code: "VND", symbol: "₫", locale: "vi_VN", suffix: true, voiceOverName: "dong"),
        CurrencyModel(currency: "Ripple", code: "XRP", symbol: "XRP", locale: "en_US", suffix: true, voiceOverName: "ripple"),
        CurrencyModel(currency: "South African rand", code: "ZAR", symbol: "R", locale: "af_ZA", voiceOverName: "rand"),
        CurrencyModel(currency: "Stellar", code: "XLM", symbol: "XLM", locale: "en_US", suffix: true, voiceOverName: "stellar"),
        CurrencyModel(currency: "Yearn finance", code: "YFI", symbol: "YFI", locale: "en_US", suffix: true, voiceOverName: "yearn finance"),
    ]
}
