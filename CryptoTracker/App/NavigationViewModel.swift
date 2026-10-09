//
//  NavigationViewModel.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-18.
//

import Foundation
import SwiftUI

@MainActor @Observable
final class NavigationViewModel {
    var navPath = [NavigationScreens]() {
        didSet {
            Task {
                await networkManager.setCurrentScreen(navPath.last?.rawValue(currentTab: selectedTab.tabName) ?? "Loading")
            }
        }
    }
    
    var showForceUpdate = false
    var isTabBarOverlayShowing = false
    
    var newsUrl: String?
    var showCalculator = false

    var allStartingDataDownloaded = false
    var showMoreTip = false
    var showBuyPro = false

    var tabbarDelay = false

    var forceCoverTabbar = false
    
    var selectedTab = SettingsManager.shared.getLatestTab() {
        didSet {
            if oldValue == selectedTab {
                doubleTappedTab()
            } else {
                if let oldTab = oldValue.tabToScreenLabel, let newTab = selectedTab.tabToScreenLabel {
                    AnalyticsManager.shared.log(
                        TabSwitched(fromTab: oldTab, toTab: newTab)
                    )
                }
                SettingsManager.shared.set(data: selectedTab, key: AppSettingKey.latestTab)
            }
            
            if showMoreTip && selectedTab == 4 {
                showMoreTip = false
            }
            
            if selectedTab == 4 {
                let nextPopupDate = Calendar.current.date(byAdding: .day, value: 9999, to: Date()) ?? Date()
                SettingsManager.shared.setHasOnboardedSettings(date: nextPopupDate)
            }
        }
    }
    
    // Snackbar
    var showSnackBar = false
    var message = ""
    var buttonTitle = ""
    var snackBarType = SnackbarTypes.success
    var canShowSnackbar = true
    var buttonCallback: () -> Void = { }
    var standardSnackbarIsVisible = false
    var standardSnackbarHeight: CGFloat = 0

    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager = NetworkManagerImp.shared) {
        self.networkManager = networkManager
    }
    
    func doubleTappedTab() {
        NotificationCenter.default.post(name: Notification.Name.tabDoubleTapped, object: nil, userInfo: [String.tabIndex : selectedTab])
    }

    func navigateToTab(_ tab: Int) {
        Task { @MainActor in
            self.resetAllData()
            self.navPath = [.MainFlow]
            self.selectedTab = tab
        }
    }
    
    func portfolioUrlOpened() {
        AnalyticsManager.shared.log(DeeplinkNavigate(toScreen: .portfolio))
        navigateToTab(1)
    }
    
    func fearGreedUrlOpened() {
        AnalyticsManager.shared.log(DeeplinkNavigate(toScreen: .fearGreed))
        Task { @MainActor in
            self.resetAllData()
            self.navPath = [.MainFlow, .FearGreed]
        }
    }
    
    func feedbackUrlOpened() {
        AnalyticsManager.shared.log(DeeplinkNavigate(toScreen: .feedback))
        Task { @MainActor in
            self.resetAllData()
            self.navPath = [.MainFlow, .Feedback]
        }
    }
    
    func referralUrlOpened(code: String) {
        AnalyticsManager.shared.log(DeeplinkNavigate(toScreen: .referral))
        Task { @MainActor in
            self.resetAllData()
            self.selectedTab = 4
            self.navPath = [.MainFlow, .Referral(referralCode: code)]
        }
    }

    func goToPriceAlerts(delay: Double = 0) {
        AnalyticsManager.shared.log(DeeplinkNavigate(toScreen: .priceAlerts))
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            self.resetAllData()
            self.navPath = [.MainFlow, .PriceAlerts]
        }
    }
    
    func resetAllData() {
        hideTabBarOverlay()

        newsUrl = nil
        showCalculator = false
        showMoreTip = false
        showBuyPro = false
        forceCoverTabbar = false
    }

    func showTabBarOverlay() {
        isTabBarOverlayShowing = true
    }
    
    func hideTabBarOverlay() {
        isTabBarOverlayShowing = false
        NotificationCenter.default.post(name: .closeAllOverlays, object: nil)
    }
    
    func hideSheets() {
        newsUrl = nil
        showBuyPro = false
    }
    
    func deepLink(url: String?) {
        guard let url = url, !url.isEmpty, url != "CoinCurrently,CNCR", url != .appName else {
            return
        }
        
        switch DeeplinkHandler.getLink(url: url) {
        case .home:
            AnalyticsManager.shared.log(DeeplinkNavigate(toScreen: .home))
            navigateToTab(0)
        case .portfolio:
            portfolioUrlOpened()
        case .marketTab:
            AnalyticsManager.shared.log(DeeplinkNavigate(toScreen: .market))
            navigateToTab(2)
        case .news:
            AnalyticsManager.shared.log(DeeplinkNavigate(toScreen: .news))
            navigateToTab(3)
        case .settings:
            AnalyticsManager.shared.log(DeeplinkNavigate(toScreen: .settings))
            navigateToTab(4)
        case .fearGreed:
            fearGreedUrlOpened()
        case .priceAlerts:
            goToPriceAlerts()
        case .globalMarket:
            AnalyticsManager.shared.log(DeeplinkNavigate(toScreen: .globalMarket))
            deepLink(to: .GlobalMarket)
        case .gasFees:
            AnalyticsManager.shared.log(DeeplinkNavigate(toScreen: .gasFees))
            deepLink(to: .GasFees)
        case .market(let url):
#if IS_APP
            UIApplication.shared.open(url)
#endif
        case .feedback:
            AnalyticsManager.shared.log(DeeplinkNavigate(toScreen: .feedback))
            deepLink(to: .Feedback)
        case .referral(let code):
            referralUrlOpened(code: code)
        case .cryptoDetail(let id, let symbol):
            let model = CurrencyDataModel(id: id, symbol: symbol)
            AnalyticsManager.shared.log(
                DeeplinkNavigate(
                    toScreen: .cryptoDetail,
                    coinName: model.name ?? model.symbol ?? symbol
                )
            )
            deepLink(to: .CryptoDetail(currencyDataModel: model))
        case .web(let url):
            if !navPath.contains(.MainFlow) {
                navPath.append(.MainFlow)
            }
            
            showCalculator = false
            
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(showCalculator || newsUrl != nil ? 0.75 : 0))
                self.newsUrl = url
            }
            
            if newsUrl != url {
                newsUrl = nil
            }
        case .none:
            return
        }
    }
    
    func deepLink(to: NavigationScreens) {
        resetAllData()
        navPath = [.MainFlow]
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
            self.navPath.append(to)
        }
    }

#if IS_APP
    func showSnackbar(
        message: String,
        buttonTitle: String,
        snackBarType: SnackbarTypes,
        buttonCallback: @escaping () -> Void
    ) {
        if canShowSnackbar || snackBarType == .success {
            canShowSnackbar = false
            self.message = message
            self.buttonTitle = buttonTitle
            self.snackBarType = snackBarType
            self.buttonCallback = buttonCallback
            
            showSnackBar.toggle()
            
            if snackBarType == .success {
                asyncMain(delay: 5.75) {
                    NotificationCenter.default.post(Notification(name: .showRatingView, object: nil, userInfo: [:]))
                }
            }
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.15))
            self.canShowSnackbar = true
        }
    }
#endif
}
