import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("NavigationViewModel Tests")
struct NavigationViewModelTests {

    @Test("resetAllData clears transient navigation flags")
    func resetAllDataClearsFlags() {
        let viewModel = NavigationViewModel(networkManager: MockRepoNetworkManager())
        viewModel.webUrl = "https://example.com"
        viewModel.showCalculator = true
        viewModel.showMoreTip = true
        viewModel.forceCoverTabbar = true
        viewModel.showTabBarOverlay()

        viewModel.resetAllData()

        #expect(viewModel.webUrl == nil)
        #expect(viewModel.showCalculator == false)
        #expect(viewModel.showMoreTip == false)
        #expect(viewModel.forceCoverTabbar == false)
        #expect(viewModel.isTabBarOverlayShowing == false)
    }

    @Test("deepLink ignores empty and app-name urls")
    func deepLinkIgnoresEmptyUrls() {
        let viewModel = NavigationViewModel(networkManager: MockRepoNetworkManager())

        viewModel.deepLink(url: nil)
        viewModel.deepLink(url: "")
        viewModel.deepLink(url: .appName)

        #expect(viewModel.navPath.isEmpty)
    }

    @Test("hideSheets closes the web sheet")
    func hideSheetsClosesSheets() {
        let viewModel = NavigationViewModel(networkManager: MockRepoNetworkManager())
        viewModel.webUrl = "https://example.com"

        viewModel.hideSheets()

        #expect(viewModel.webUrl == nil)
    }
}
