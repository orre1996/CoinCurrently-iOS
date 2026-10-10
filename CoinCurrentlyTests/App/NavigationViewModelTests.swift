import Foundation
import Testing
@testable import CoinCurrently

@MainActor
@Suite("NavigationViewModel Tests")
struct NavigationViewModelTests {

    @Test("resetAllData clears transient navigation flags")
    func resetAllDataClearsFlags() {
        let viewModel = NavigationViewModel(networkManager: MockRepoNetworkManager())
        viewModel.newsUrl = "https://example.com"
        viewModel.showCalculator = true
        viewModel.showMoreTip = true
        viewModel.showBuyPro = true
        viewModel.forceCoverTabbar = true
        viewModel.showTabBarOverlay()

        viewModel.resetAllData()

        #expect(viewModel.newsUrl == nil)
        #expect(viewModel.showCalculator == false)
        #expect(viewModel.showMoreTip == false)
        #expect(viewModel.showBuyPro == false)
        #expect(viewModel.forceCoverTabbar == false)
        #expect(viewModel.isTabBarOverlayShowing == false)
    }

    @Test("deepLink ignores empty and app-name urls")
    func deepLinkIgnoresEmptyUrls() {
        let viewModel = NavigationViewModel(networkManager: MockRepoNetworkManager())
        viewModel.showBuyPro = true

        viewModel.deepLink(url: nil)
        viewModel.deepLink(url: "")
        viewModel.deepLink(url: .appName)

        #expect(viewModel.showBuyPro)
        #expect(viewModel.navPath.isEmpty)
    }

    @Test("hideSheets closes the news and paywall sheets")
    func hideSheetsClosesSheets() {
        let viewModel = NavigationViewModel(networkManager: MockRepoNetworkManager())
        viewModel.newsUrl = "https://example.com"
        viewModel.showBuyPro = true

        viewModel.hideSheets()

        #expect(viewModel.newsUrl == nil)
        #expect(viewModel.showBuyPro == false)
    }
}
