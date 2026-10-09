//
//  ReferralViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/30/26.
//

import UIKit

@MainActor
@Observable
final class ReferralViewModel {
    private let referralRepository: ReferralRepository

    var referralQRImage: UIImage?
    var referralLink: String?
    var redeemCodeInput = ""
    var isLoadingReferralCode = false
    var isRedeemingCode = false
    var redeemSucceeded = false
    var redeemErrorMessage: String?

    var showError: Bool {
        redeemErrorMessage != nil
    }

    var user: UserResponse?
    
    var currentReferrals: Int = 0
    
    private var referralCodeValue: String?
    
    var referralCode: String? {
        referralCodeValue
    }

    init(
        referralRepository: ReferralRepository = ReferralRepositoryImp.shared,
        redeemCodeInput: String = ""
    ) {
        self.referralRepository = referralRepository
        self.redeemCodeInput = redeemCodeInput
    }
    
    func setStartData() async {
        await referralRepository.ensureCacheLoaded()
        
        if let user = await referralRepository.cachedUser?.data {
            self.user = user
            currentReferrals = user.referralCount
        }
        
        if let result = await referralRepository.cachedReferralCode?.data.asResult {
            applyReferralCode(result)
        }
    }

    func loadReferralCode() async {
        guard !isLoadingReferralCode else { return }

        isLoadingReferralCode = true
        defer { isLoadingReferralCode = false }

        guard let result = await referralRepository.getReferralCode() else { return }
        applyReferralCode(result)
    }
    
    private func applyReferralCode(_ result: ReferralCodeResult) {
        referralQRImage = result.qrImage
        referralCodeValue = result.code
        referralLink = result.inviteLink
    }

    func redeemCode() async {
        let trimmedCode = redeemCodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty, !isRedeemingCode else { return }

        isRedeemingCode = true
        defer { isRedeemingCode = false }

        let result = await referralRepository.redeemCode(refCode: trimmedCode)
        redeemSucceeded = result == .success
        redeemErrorMessage = result.errorMessage

        if redeemSucceeded {
            redeemCodeInput = ""
        }
    }
    
    func getUser() async {
        guard let response = await referralRepository.getUser(ignoreCache: true) else { return }
        user = response
        currentReferrals = response.referralCount
    }
}
