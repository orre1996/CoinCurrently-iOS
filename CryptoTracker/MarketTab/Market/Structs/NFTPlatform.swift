//
//  NFTPlatform.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/26/26.
//

import Foundation

struct NFTPlatform: Codable, Hashable, Equatable {
    var id: String? = nil
    var name: String? = nil
    var image: Logo? = nil
    var native_coin_id: String?
    
    var accessibilityTitle: String {
        if id == "all" {
            return "All Chains"
        }
        return name ?? "All Chains"
    }
}

