//
//  CachedData.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-02-06.
//

import Foundation

struct CachedData<T: Codable>: Codable, @unchecked Sendable {
    var data: T
    var date: Date
}
