//
//  DerivativeModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-10-25.
//

import Foundation

struct Derivative: Codable, Equatable, Hashable {
    var name: String? = nil
    
    /// Name with "Futures", "Derivatives" and parenthetical content removed.
    var displayName: String? {
        guard let name else { return nil }
        var result = name
            .replacingOccurrences(of: "Futures", with: "")
            .replacingOccurrences(of: "Derivatives", with: "")
        result = result.replacingOccurrences(of: #"\([^)]*\)"#, with: "", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    var id: String? = nil
    var open_interest_btc: Double? = nil
    var trade_volume_24h_btc: String? = nil
    var number_of_perpetual_pairs: Int? = nil
    var number_of_futures_pairs: Int? = nil
    var image: String? = nil
    var year_established: Int? = nil
    var country: String? = nil
    var description: String? = nil
    var url: String? = nil
    var tickers: [DerivativeDetail]? = nil
    
    func copy(withId: String) -> Derivative {
        return Derivative(
            name: name,
            id: withId,
            open_interest_btc: open_interest_btc,
            trade_volume_24h_btc: trade_volume_24h_btc,
            number_of_perpetual_pairs: number_of_perpetual_pairs,
            number_of_futures_pairs: number_of_futures_pairs,
            image: image,
            year_established: year_established,
            country: country,
            description: description,
            url: url,
            tickers: tickers
        )
    }
}


