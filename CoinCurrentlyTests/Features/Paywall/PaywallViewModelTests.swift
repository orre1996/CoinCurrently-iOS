import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("PaywallViewModel Tests")
struct PaywallViewModelTests {

    @Test("subscribe button offers a trial only when the user is eligible")
    func subscribeButtonOffersTrialWhenEligible() {
        let viewModel = makeViewModel()

        viewModel.isEligableForTrial = false
        #expect(viewModel.subscribeButtonText == Localization.string("Upgrade Now"))

        viewModel.isEligableForTrial = true
        #expect(viewModel.subscribeButtonText == Localization.string("Start Your Free Trial"))
    }

    @Test("buying without a selected product does nothing")
    func buyingWithoutProductDoesNothing() async {
        let viewModel = makeViewModel()

        let purchased = await viewModel.buyProduct()

        #expect(purchased == false)
        #expect(viewModel.isLoading == false)
    }

    @Test("restore reports failure when nothing can be restored")
    func restoreReportsFailure() async {
        let viewModel = makeViewModel()

        let restored = await viewModel.restorePurchases()

        #expect(restored == false)
    }

    private func makeViewModel() -> PaywallViewModelImp {
        PaywallViewModelImp(
            storeKitManager: MockRepoStoreKitManager(),
            cachedStorageManager: emptyStorageManager(),
            settingsManager: SettingsManager.shared,
            firebaseMananager: MockFirebaseManager()
        )
    }
}
