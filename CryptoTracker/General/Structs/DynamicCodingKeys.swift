//
//  DynamicCodingKeys.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-13.
//

import Foundation

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int? { return nil }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}
