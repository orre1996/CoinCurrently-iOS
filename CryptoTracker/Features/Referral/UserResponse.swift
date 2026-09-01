//
//  UserResponse.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 8/9/26.
//

import Foundation

struct UserResponse: Codable {
    let referralCount: Int
    let user: RemoteUser
}

struct RemoteUser: Codable {
    let uid: String
    let displayName: String?
    let email: String?
    let phoneNumber: String?
    let photoUrl: String?
    let providerId: String
    let emailVerified: Bool
    let disabled: Bool
    let providerData: [ProviderUserData]
    let tokensValidAfterTimestamp: String
    let userMetaData: UserMetaData
    let customClaims: UserCustomClaims?
    let tenantId: String?
}

struct ProviderUserData: Codable {
    let uid: String?
    let displayName: String?
    let email: String?
    let phoneNumber: String?
    let photoUrl: String?
    let providerId: String?
}

struct UserMetaData: Codable {
    let creationTimestamp: String
    let lastSignInTimestamp: String
    let lastRefreshTimestamp: String
}

struct UserCustomClaims: Codable {
    let fcmToken: String?
    let preferredCurrency: String?

    enum CodingKeys: String, CodingKey {
        case fcmToken = "fcm_token"
        case preferredCurrency = "preferred_currency"
    }
}
