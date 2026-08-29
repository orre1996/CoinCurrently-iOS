//
//  TreasuryEntity.swift
//  CoinCurrently
//

import Foundation

enum TreasuryEntity: String, CaseIterable, Codable, Sendable {
    case companies
    case governments

    var displayName: String {
        switch self {
        case .companies:
            "Company"
        case .governments:
            "Government"
        }
    }

    var apiEntityType: String {
        switch self {
        case .companies:
            "company"
        case .governments:
            "government"
        }
    }
}

enum TreasuryEntityFilter: String, CaseIterable, Codable, Sendable {
    case all
    case companies
    case governments

    var title: String {
        switch self {
        case .all:
            "All"
        case .companies:
            "Company"
        case .governments:
            "Government"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .all:
            "All holders"
        case .companies:
            "Companies only"
        case .governments:
            "Governments only"
        }
    }
}
