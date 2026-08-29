//
//  CoinsListModel.swift
//  Cryptocurrently
//
//  Created by Oscar Berggren on 2020-12-01.
//

import Foundation

struct CoinsListModel: Codable, Hashable, Equatable {
    var id: String? = nil
    var symbol: String? = nil
    var name: String? = nil
    var activated_at: Int? = nil
}
