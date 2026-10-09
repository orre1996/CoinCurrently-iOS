//
//  CoinCurrentlyApp.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-23.
//

import StoreKit
import SwiftUI

@MainActor @Observable
class DeeplinkHelper {
    var deepLinkUrl = ""
}

var isRunningTests: Bool {
    ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil || NSClassFromString("XCTestCase") != nil
}

@main
struct MainEntry: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            if isRunningTests {
                LoadingScreen()
            } else {
                CoinCurrentlyApp(appDelegate: appDelegate)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
            }
        }
    }
}

extension UITabBarController {
    var height: CGFloat {
        return self.tabBar.frame.size.height
    }
    
    var width: CGFloat {
        return self.tabBar.frame.size.width
    }
}

struct CoinCurrentlyApp: View {
    let appDelegate: AppDelegate
    
    @AppStorage("appColorScheme")
    private var appColorScheme: AppColorScheme = .dark
    
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    
    @EnvironmentObject private var sceneDelegate: SceneDelegate
    
    @State private var authViewModel = AuthenticationViewModelImp()
    @State private var viewModel = NavigationViewModel()
    
    private var deeplinkHelper: DeeplinkHelper {
        appDelegate.deeplinkHelper
    }
    @State private var canAuthenticate = false
    @State private var showWhatsNew = false

    let appIconShortcutsManager = AppIconShortcutsManager()
    
    private var shouldAppendMainFlow: Bool {
        !viewModel.navPath.contains(.MainFlow) &&
        (deeplinkHelper.deepLinkUrl.isEmpty ||
         deeplinkHelper.deepLinkUrl == .appName ||
         deeplinkHelper.deepLinkUrl == "CoinCurrently,CNCR")
    }
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = Color.surface.uiColor
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .gray
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        UITabBarItem.appearance().setTitleTextAttributes([.font: UIFont.satoshiMedium(14)], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([.font: UIFont.satoshiMedium(14)], for: .selected)
    }
    
    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack(alignment: .bottom) {
            NavigationStack(path: $viewModel.navPath) {
                LoadingScreen(
                    isAllDataDownloaded: viewModel.allStartingDataDownloaded,
                    showUnlockButton: viewModel.allStartingDataDownloaded && authViewModel.isAppLocked,
                    showAuthenticationError: authViewModel.showError,
                    authenticateUser: {
                        await allDataDownloaded()
                    }
                )
                .navigationDestination(for: NavigationScreens.self) { screen in
                    screen.screenView
                }
            }
            .environment(viewModel)

            SnackbarView(
                showSnackBar: $viewModel.showSnackBar,
                message: $viewModel.message,
                buttonTitle: $viewModel.buttonTitle,
                type: viewModel.snackBarType,
                isTabbarHidden: viewModel.navPath.count > 1,
                isOverlayShowing: viewModel.isTabBarOverlayShowing,
                isPresented: $viewModel.standardSnackbarIsVisible,
                reportedHeight: $viewModel.standardSnackbarHeight,
                overlayPressed: {
                    viewModel.hideTabBarOverlay()
                },
                buttonAction: viewModel.buttonCallback
            )
            .zIndex(2)
            
            Color.overlayBackground
                .opacity(viewModel.showMoreTip ? 0.7 : 0)
                .animation(.default, value: viewModel.showMoreTip)
                .ignoresSafeArea()
                .allowsHitTesting(viewModel.showMoreTip)
                .zIndex(1)
            
            if viewModel.allStartingDataDownloaded && authViewModel.isAppLocked && canAuthenticate || authViewModel.showLoadingScreen {
                LoadingScreen(
                    isAllDataDownloaded: viewModel.allStartingDataDownloaded,
                    showUnlockButton: authViewModel.isAppLocked,
                    showAuthenticationError: authViewModel.showError,
                    authenticateUser: {
                        await allDataDownloaded()
                    }
                )
                .transition(AnyTransition.move(edge: .leading).animation(.easeInOut))
                .zIndex(4)
            }
            
            if viewModel.showForceUpdate {
                ForceUpdateView()
            }
        }
        .injectSafeAreaInsetsEnvironment()
        .preferredColorScheme(appColorScheme.preferredScheme)
        .task {
            SiriNavigationManager.register(viewModel)
            
            await ToplistRepositoryImp.shared.migrateFavorites()
            await PortfolioRepositoryImp.shared.migratePortfolio()
            await CryptoDetailRepositoryImp.shared.migrateSavedCoins()

            Task {
                await StoreKitManagerImp.shared.setStartData()
                await StoreKitManagerImp.shared.fetchStoreProducts()
            }

            Task {
                let needsToUpdate = await FirebaseManagerImp.shared.login()
                _ = GlobalMarketRepositoryImp.shared
                
                guard !needsToUpdate else {
                    viewModel.showForceUpdate = true
                    return
                }

                _ = await appDelegate.setupPush()
            }
            
            await ToplistRepositoryImp.shared.ensureCacheLoaded()
            if await ToplistRepositoryImp.shared.cachedSmallToplist?.data.isEmpty ?? true {
                _ = await ToplistRepositoryImp.shared.getSmallToplist()
            }
            
            if SettingsManager.shared.get(key: AppSettingKey.storedWhatsNewVersion) != AppSettingKey.currentWhatsNewVersion.rawValue {
                showWhatsNew = true
                SettingsManager.shared.set(data: AppSettingKey.currentWhatsNewVersion.rawValue, key: AppSettingKey.storedWhatsNewVersion)
            }
            
            await allDataDownloaded()
        }
        .if(isPhone) { view in
            view.sheet(item: $viewModel.newsUrl) { url in
                WebViewContainer(url: url)
            }
        }
        .if(!isPhone) { view in
            view.fullScreenCover(item: $viewModel.newsUrl) { url in
                WebViewContainer(url: url)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showBuyPro) {
            PaywallScreen()
        }
        .sheet(isPresented: $showWhatsNew) {
            WhatsNewSheet()
        }
        .onReceive(NotificationCenter.default.publisher(for: .backFromBackground, object: nil)) { notification in
            Task {
                _ = await appDelegate.setupPush()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .fromPush, object: nil)) { notification in
            asyncMain(delay: 1) {
                guard let cryptoID = notification.userInfo?["cryptoID"] as? String else { return }
                
                if viewModel.allStartingDataDownloaded {
                    viewModel.deepLink(url: cryptoID)
                    deeplinkHelper.deepLinkUrl = ""
                } else {
                    deeplinkHelper.deepLinkUrl = cryptoID
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .syncPremiumStatus, object: nil)) { notification in
            if let _ = notification.userInfo?["syncPremiumStatus"] as? String {
                WatchConnectivityViewModel.shared.sendPremiumStatusToWatch()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .Snackbar, object: nil)) { notification in
            viewModel.showSnackbar(
                message: notification.userInfo?["message"] as? String ?? "",
                buttonTitle: "",
                snackBarType: notification.userInfo?["type"] as? SnackbarTypes ?? .success,
                buttonCallback: { }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .buyPro, object: nil)) { notification in
            viewModel.showBuyPro = true
        }
        .onOpenURL { url in
            deeplinkHelper.deepLinkUrl = url.absoluteString
        }
        .onChange(of: deeplinkHelper.deepLinkUrl) { _, url in
            guard !url.isEmpty else { return }
            
            guard !authViewModel.isAppLocked, viewModel.allStartingDataDownloaded else {
                return
            }
            
            asyncMain {
                viewModel.deepLink(url: url)
                deeplinkHelper.deepLinkUrl = ""
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
                case .background:
                    appIconShortcutsManager.configure()
                    authViewModel.lockApp()
                    
                    if SettingsManager.shared.get(key: AppSettingKey.authenticationEnabled) ?? false {
                        viewModel.hideSheets()
                    }
                    
                case .inactive:
                    guard SettingsManager.shared.get(key: AppSettingKey.authenticationEnabled) ?? false, !authViewModel.isAppLocked else { return }
                    
                    authViewModel.showLoadingScreen = true
                    authViewModel.showError = false
                case .active:
                    guard authViewModel.isAppLocked, authViewModel.askForAuthAgain else {
                        authViewModel.showLoadingScreen = false
                        return
                    }
                    
                    authViewModel.askForAuthAgain = false
                    
                    Task {
                        await allDataDownloaded()
                    }
    
                default:
                    break
            }
        }
        .onChange(of: sceneDelegate.shortCutAction) { _, url in
            guard !url.isEmpty, viewModel.allStartingDataDownloaded else { return }
            
            asyncMain {
                viewModel.deepLink(url: url)
                sceneDelegate.shortCutAction = ""
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showRatingView, object: nil)) { notification in
            if notification.userInfo?["force"] as? Bool ?? false {
                rateNowPressed(delay: 2)
                return
            }
            
            if let date = SettingsManager.shared.getActionRatingDate(), Date() > date {
                rateNowPressed()
            }
        }
    }
    
    private func allDataDownloaded() async {
        viewModel.allStartingDataDownloaded = true
        
        if SettingsManager.shared.get(key: AppSettingKey.authenticationEnabled) ?? false && authViewModel.isAppLocked {
            guard await !authViewModel.authenticate() else { return }
        }
        
        canAuthenticate = true
        
        if shouldAppendMainFlow {
            viewModel.navPath.append(.MainFlow)
        }
        
        if !sceneDelegate.shortCutAction.isEmpty {
            viewModel.deepLink(url: sceneDelegate.shortCutAction)
            sceneDelegate.shortCutAction = ""
        } else if !deeplinkHelper.deepLinkUrl.isEmpty {
            viewModel.deepLink(url: deeplinkHelper.deepLinkUrl)
            deeplinkHelper.deepLinkUrl = ""
        } else {
            SiriNavigationManager.consumePending(with: viewModel)
        }
        
        if let date = SettingsManager.shared.getRatingPopupDate(), Date() > date {
            rateNowPressed()
        } else if SettingsManager.shared.getRatingPopupDate() == nil {
            let nextPopupDate = Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()
            SettingsManager.shared.setRatingPopupDate(date: nextPopupDate)
        }
        
        if SettingsManager.shared.getActionRatingDate() == nil {
            let nextActionPopupDate = Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()
            SettingsManager.shared.setActionRatingDate(date: nextActionPopupDate)
        }
    }
    
    private func rateNowPressed(delay: Double = 5) {
        let nextPopupDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        SettingsManager.shared.setRatingPopupDate(date: nextPopupDate)
        
        let nextActionPopupDate = Calendar.current.date(byAdding: .day, value: 21, to: Date()) ?? Date()
        SettingsManager.shared.setActionRatingDate(date: nextActionPopupDate)
        
        asyncMain(delay: delay) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                AppStore.requestReview(in: scene)
            }
        }
    }
}
