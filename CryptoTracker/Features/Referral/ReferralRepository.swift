//
//  ReferralRepository.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/30/26.
//

import UIKit

protocol ReferralRepository: Actor {
    var cachedUser: CachedData<UserResponse>? { get }
    var cachedReferralCode: CachedData<CachedReferralCodeData>? { get }
    func ensureCacheLoaded() async
    func getReferralCode() async -> ReferralCodeResult?
    func redeemCode(refCode: String) async -> RedeemCodeResult
    func getUser(ignoreCache: Bool) async -> UserResponse?
}

final actor ReferralRepositoryImp: ReferralRepository {
    static let shared = ReferralRepositoryImp()

    private let networkManager: NetworkManager
    private let storageManager: CachedStorageManager
    private(set) var cachedUser: CachedData<UserResponse>?
    private(set) var cachedReferralCode: CachedData<CachedReferralCodeData>?
    private var hasLoadedFromStorage = false

    init(
        networkManager: NetworkManager = NetworkManagerImp.shared,
        storageManager: CachedStorageManager = CachedStorageManagerImp.shared
    ) {
        self.networkManager = networkManager
        self.storageManager = storageManager
        self.cachedUser = nil
        self.cachedReferralCode = nil
    }

    func ensureCacheLoaded() async {
        guard !hasLoadedFromStorage else { return }
        hasLoadedFromStorage = true
        
        if let user: UserResponse = await networkManager.getCached(endpoint: .user()) {
            cachedUser = CachedData(data: user, date: Date())
        }
        
        if cachedReferralCode == nil {
            cachedReferralCode = await storageManager.load(type: LocalStorageKeys.referralCode)
        }
    }

    func getReferralCode() async -> ReferralCodeResult? {
        await ensureCacheLoaded()
        
        guard let response = await networkManager.getRaw(endpoint: .referralCode) else {
            return cachedReferralCode?.data.asResult
        }
        
        guard let result = ReferralCodeResult.decode(data: response.data, response: response.response) else {
            return cachedReferralCode?.data.asResult
        }
        
        let updated = CachedData(
            data: CachedReferralCodeData(result: result, imageData: response.data),
            date: Date()
        )
        cachedReferralCode = updated
        await storageManager.save(type: LocalStorageKeys.referralCode, data: updated)
        
        return result
    }

    func redeemCode(refCode: String) async -> RedeemCodeResult {
        let (_, status): (EmptyResponse?, Int) = await networkManager.post(
            endpoint: .redeemCode,
            bodyStruct: RedeemCodeRequest(refCode: refCode)
        )

        let result = RedeemCodeResult(statusCode: status)

#if IS_APP
        if result == .success {
            await FirebaseManagerImp.shared.syncRevenueCatCustomerInfo()
        }
#endif

        return result
    }

    func getUser(ignoreCache: Bool = false) async -> UserResponse? {
        await ensureCacheLoaded()
        let response: UserResponse? = await networkManager.get(endpoint: .user(ignoreCache: ignoreCache))

        if let response {
            cachedUser = CachedData(data: response, date: Date())
        }

        return response ?? cachedUser?.data
    }
}
