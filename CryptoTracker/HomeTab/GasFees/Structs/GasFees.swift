//
//  GasFees.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-03-18.
//

import SwiftUI

struct GasFees: Codable, Equatable {
    let gasFeeData: [GasResult]?
}

struct GasResult: Codable, Equatable {
    let lastBlock: String
    let sK_Date: String
    let safeGasPrice: String
    let proposeGasPrice: String
    let fastGasPrice: String
    let suggestBaseFee: String
    let gasUsedRatio: String
}
