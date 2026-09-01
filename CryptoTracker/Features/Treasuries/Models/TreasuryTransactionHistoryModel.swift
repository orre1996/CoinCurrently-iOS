//
//  TreasuryTransactionHistoryModel.swift
//  CoinCurrently
//

import Foundation

struct TreasuryTransactionHistoryModel: Codable, Equatable {
    let transactions: [TreasuryTransaction]?
}

struct TreasuryTransaction: Codable, Equatable, Hashable {
    let date: Double?
    let source_url: String?
    let coin_id: String?
    let type: TreasuryTransactionType?
    let holding_net_change: Double?
    let transaction_value_usd: Double?
    let holding_balance: Double?
    let average_entry_value_usd: Double?
}

enum TreasuryTransactionType: String, Codable {
    case buy
    case sell
}
