//
//  CryptoDataStore.swift
//  CoinCurrentlyWatch Extension
//
//  Created by Oscar Berggren on 2021-08-27.
//

import Foundation

private let LastCryptoKey = "LastCryptoKey"

struct CryptoDataStore {
    let defaults = UserDefaults.standard
    let jsonDecoder = JSONDecoder()
    let jsonEncoder = JSONEncoder()
    
    var lastCrypto: CurrencyDataModel? {
        get {
            guard let data = defaults.data(forKey: LastCryptoKey),
                  let currency = try? jsonDecoder.decode(CurrencyDataModel.self, from: data)
            else {
                return nil
            }
            
            return currency
        }
        
        set {
            guard let value = newValue,
                  let data = try? jsonEncoder.encode(value)
            else {
                return
            }

            defaults.set(data, forKey: LastCryptoKey)
        }
    }
}
