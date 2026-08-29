//
//  Data+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-09.
//

import Foundation

extension Data {
    var toJson: Any? {
        return try? JSONSerialization.jsonObject(with: self, options: .mutableContainers)
    }
    
    var toString: String {
        return String(decoding: self, as: UTF8.self)
    }
}
