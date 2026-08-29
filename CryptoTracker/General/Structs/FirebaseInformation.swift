//
//  FirebaseInformation.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/21/25.
//

import Foundation

struct FirebaseInformation: Codable {
    let minVersion: String
    let maxVersion: String
    let message: String
    let messageId: String
}
