import Foundation
import UIKit
import Testing
@testable import CoinCurrently

@MainActor
@Suite("ReferralViewModel Tests")
struct ReferralViewModelTests {

    @Test("loadReferralCode stores the code and invite link")
    func loadReferralCodeStoresLink() async {
        let repo = MockVMReferralRepository()
        await repo.setCode(ReferralCodeResult(qrImage: UIImage(), code: "OSCAR"))
        let viewModel = ReferralViewModel(referralRepository: repo)

        await viewModel.loadReferralCode()

        #expect(viewModel.referralCode == "OSCAR")
        #expect(viewModel.referralLink == "https://coincurrently.app/invite/OSCAR")
        #expect(viewModel.isLoadingReferralCode == false)
    }

    @Test("redeemCode clears the input after success")
    func redeemCodeClearsInput() async {
        let repo = MockVMReferralRepository()
        await repo.setRedeem(.success)
        let viewModel = ReferralViewModel(referralRepository: repo, redeemCodeInput: " OSCAR ")

        await viewModel.redeemCode()

        #expect(viewModel.redeemSucceeded)
        #expect(viewModel.redeemCodeInput.isEmpty)
        #expect(viewModel.showError == false)
    }

    @Test("redeemCode keeps the input and message when the code is invalid")
    func redeemCodeKeepsInvalidInput() async {
        let repo = MockVMReferralRepository()
        await repo.setRedeem(.invalidCode)
        let viewModel = ReferralViewModel(referralRepository: repo, redeemCodeInput: "nope")

        await viewModel.redeemCode()

        #expect(viewModel.redeemSucceeded == false)
        #expect(viewModel.redeemCodeInput == "nope")
        #expect(viewModel.showError)
        #expect(viewModel.redeemErrorMessage != nil)
    }

    @Test("blank codes are ignored")
    func blankCodesAreIgnored() async {
        let viewModel = ReferralViewModel(
            referralRepository: MockVMReferralRepository(),
            redeemCodeInput: "   "
        )

        await viewModel.redeemCode()

        #expect(viewModel.redeemSucceeded == false)
        #expect(viewModel.isRedeemingCode == false)
    }
}

private extension MockVMReferralRepository {
    func setCode(_ result: ReferralCodeResult) {
        referralCode = result
    }

    func setRedeem(_ result: RedeemCodeResult) {
        redeemResult = result
    }
}
