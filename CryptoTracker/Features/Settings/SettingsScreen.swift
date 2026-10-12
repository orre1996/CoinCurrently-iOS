//
//  SettingsScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-05-24.
//

import SwiftUI
import UIKit
import StoreKit
import Foundation
import FirebaseMessaging

struct SettingsScreen: View {
    private let storeKitManager: StoreKitManager
    
    @AppStorage("appColorScheme")
    var appColorScheme: AppColorScheme = .dark
    
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    
    init(storeKitManager: StoreKitManager = StoreKitManagerImp.shared) {
        self.storeKitManager = storeKitManager
    }
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.colorScheme) private var scheme
    
    @ScaledMetric private var scale: CGFloat = 1

    @State var authViewModel = AuthenticationViewModelImp()

    @State private var pageID = UUID()
    @State private var resetAppOpen = false
    @State private var scrollToTopActive = false

    // Global settings
    @State private var showChangesInPercent: Bool = SettingsManager.shared.get(key: GlobalSettingKey.changesInPercent) ?? true
    @State private var selectedTimeframe: PreferredTimeframe = SettingsManager.shared.get(key: GlobalSettingKey.selectedTimeframe) ?? PreferredTimeframe.weekly
    @State private var selectedStartTab: StartTab = SettingsManager.shared.get(key: AppSettingKey.startTab) ?? .home
    @State private var webSocketEnabled = false
    
    // App settings
    @State private var selectedCurrency: CurrencyModel = SettingsManager.shared.get(key: GlobalSettingKey.selectedCurrency) ?? CurrencyModel()
    @State private var selectedLanguage: AppLanguagePreference = .stored
    @State private var appLanguage = AppLanguagePreference.stored
    @State private var showTransactinosInGraph: Bool = SettingsManager.shared.get(key: AppSettingKey.transactionInGraph) ?? true
    @State private var lockRotation: Bool = SettingsManager.shared.get(key: AppSettingKey.lockRotation) ?? false
    @State private var isAuthenticationEnabled: Bool = SettingsManager.shared.get(key: AppSettingKey.authenticationEnabled) ?? false
    @State private var colorBlindnessFilterEnabled: Bool = SettingsManager.shared.get(key: AppSettingKey.colorBlindnessFilter) ?? false

    @State private var startTab: StartTab = SettingsManager.shared.get(key: AppSettingKey.startTab) ?? .home

    @State private var isSelectingStartTab = false
    @State private var isSelectingTheme = false
    @State private var isSelectingCurrency = false
    @State private var isSelectingLanguage = false
    @State private var currentSubscription: String?
    @State private var subscriptionExpirationDate: Date?
    
    @State private var isManagingSubscription = false

    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()
            
            ZStack {
                ScrollView(.vertical) {
                    ScrollViewReader { reader in
                        LazyVStack(spacing: 32) {
                            proView
                            
                            globalSettingsView
                            
                            toolsSettingsView
                            
                            securityView
                            
                            enjoyTheAppView
                            
                            legalView
                            
                            poweredView
                        }
                        .padding(
                            EdgeInsets(
                                top: 32,
                                leading: 16,
                                bottom: 32,
                                trailing: 16
                            )
                        )
                        .id(pageID)
                        .onChange(of: scrollToTopActive) {
                            withAnimation {
                                reader.scrollTo(pageID, anchor: .top)
                            }
                        }
                    }
                }
                .accessibilityHidden(resetAppOpen)
                
                if resetAppOpen {
                    ResetAppSheet(
                        close: {
                            resetAppOpen = false
                            navigationViewModel.hideTabBarOverlay()
                        }
                    )
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tabDoubleTapped, object: nil)) { notification in
            if let index = notification.userInfo?[String.tabIndex] as? Int, index == 4, !resetAppOpen {
                AnalyticsManager.shared.log(
                    TabBarDoubleTapped(fromScreen: .settings)
                )

                scrollToTopActive.toggle()
            }
        }
        .syncSubscriptionStatus(
            $currentSubscription,
            expirationDate: $subscriptionExpirationDate,
            storeKitManager: storeKitManager
        )
        .onChange(of: currentSubscription, initial: true) { _, subscription in
            webSocketEnabled = SettingsManager.shared.isWebSocketEnabled(hasPro: subscription != nil)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button(Localization.string("Close")) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .accessibilityLabel(Localization.string("Close keyboard"))
            }
        }
        .sheet(isPresented: $isSelectingTheme) {
            SettingsOptionsSheet(
                title: "App Theme",
                options: AppColorScheme.allCases.map({ $0.rawValue }),
                selectedSortOption: appColorScheme.rawValue,
                newOptionSelected: {
                    appColorScheme = AppColorScheme(rawValue: $0) ?? .light
                    AnalyticsManager.shared.log(
                        ThemeSelected(fromScreen: .settings, theme: appColorScheme)
                    )
                }
            )
        }
        .sheet(isPresented: $isSelectingStartTab) {
            SettingsOptionsSheet(
                title: "Default Tab",
                options: StartTab.allCases.map({ $0.rawValue }),
                selectedSortOption: selectedStartTab.rawValue,
                newOptionSelected: {
                    selectedStartTab = StartTab(rawValue: $0) ?? .home
                    SettingsManager.shared.set(data: selectedStartTab, key: AppSettingKey.startTab)
                    AnalyticsManager.shared.log(
                        StartTabSelected(fromScreen: .settings, tab: selectedStartTab)
                    )
                }
            )
        }
        .sheet(isPresented: $isSelectingLanguage) {
            LanguageOptionsSheet(
                selectedOption: selectedLanguage,
                newOptionSelected: {
                    selectedLanguage = $0
                    SettingsManager.shared.set(data: selectedLanguage.storageValue, key: AppSettingKey.selectedLanguage)
                    NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
                    AppIconShortcutsManager().configure()
                    WidgetReloadService.shared.forceUpdateWidgets()
                    AnalyticsManager.shared.log(
                        LanguageSelected(fromScreen: .settings, language: selectedLanguage.storageValue)
                    )
                }
            )
        }
        .sheet(isPresented: $isSelectingCurrency) {
            CurrencyOptionsSheet(
                selectedSortOption: selectedCurrency,
                newOptionSelected: {
                    selectedCurrency = $0
                    SettingsManager.shared.set(data: selectedCurrency, key: GlobalSettingKey.selectedCurrency)
                    AnalyticsManager.shared.log(
                        CurrencySelected(fromScreen: .settings, currency: selectedCurrency.currency)
                    )
                    Task {
                        await refreshCachedSections()
                        WidgetReloadService.shared.forceUpdateWidgets()
                        NotificationCenter.default.post(name: .downloadNewToplist, object: nil)
                    }
                    
                    UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { permission in
                        if permission.authorizationStatus == .authorized {
                            guard FirebaseConfigurator.configureIfNeeded(),
                                  let fcmToken = Messaging.messaging().fcmToken, !fcmToken.isEmpty else {
                                return
                            }
                            
                            Task {
                                await PriceAlertsRepositoryImp.shared.updateUser(
                                    fcmToken: fcmToken
                                )
                            }
                        }
                    })
                }
            )
        }
        .manageSubscriptionsSheet(isPresented: $isManagingSubscription)
        .onDisappear {
            resetAppOpen = false
        }
        .environment(\.locale, appLanguage.resolve().locale)
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            appLanguage = AppLanguagePreference.stored
            selectedLanguage = .stored
        }
    }

    private func abbreviatedDate(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(Localization.locale))
    }
    
    private var subscriptionStatusAccessibilityLabel: String {
        guard currentSubscription != nil else { return Localization.string("Inactive") }
        guard let expirationDate = subscriptionExpirationDate else { return Localization.string("Active") }
        return Localization.format("Active · Expires %@", abbreviatedDate(expirationDate))
    }

    @ViewBuilder
    private var subscriptionStatusSubtitle: some View {
        if currentSubscription == nil {
            Text(Localization.string("Inactive"))
                .foregroundStyle(Color.onSurfaceDimmer)
        } else if let expirationDate = subscriptionExpirationDate {
            Text(Localization.string("Active"))
                .foregroundStyle(Color.primary)
            + Text(Localization.format(" · Expires %@", abbreviatedDate(expirationDate)))
                .foregroundStyle(Color.onSurfaceDimmer)
        } else {
            Text(Localization.string("Active"))
                .foregroundStyle(Color.primary)
        }
    }
    
    // MARK: - Pro view
    private var proView: some View {
        VStack(spacing: 16) {
            Button(action: {
                AnalyticsManager.shared.log(
                    BuyProOpened(fromScreen: .settings, action: .Settings)
                )
                navigationViewModel.showBuyPro = true
            }, label: {
                HStack(spacing: 16) {
                    Image.premiumLogo
                        .resizable()
                        .frame(width: 48, height: 48)
                        .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Localization.string("CoinCurrently Pro"))
                            .font(.satoshiBold(16))
                            .foregroundStyle(Color.onSurface)
                            .multilineTextAlignment(.leading)
                        
                        subscriptionStatusSubtitle
                            .font(.satoshiBold(12))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel(subscriptionStatusAccessibilityLabel)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image.chevronRight
                        .resizable()
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                        .foregroundStyle(Color.onSurfaceDimmer)
                }
            })
            
            if currentSubscription != nil {
                Separator()
                
                SettingsNavigationView(title: "Manage Subscription") {
                    isManagingSubscription = true
                }
            }
            
            Separator()
            
            SettingsNavigationView(
                title: "Referral Program",
                accessibilityText: "Navigate to Referral Program"
            ) {
                AnalyticsManager.shared.log(
                    Navigate(fromScreen: .settings, toScreen: .referral)
                )
                navigationViewModel.navPath.append(.Referral(referralCode: ""))
            }
        }
        .cardBackground()
    }
    
    // MARK: - Global settings

    @ViewBuilder
    private var globalSettingsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionHeader(title: "Global Settings")
                .id(UUID())
            
            VStack(alignment: .leading, spacing: 16) {
                SettingsNavigationView(
                    title: "Currency",
                    subTitle: "\(selectedCurrency.code) (\(selectedCurrency.symbol))",
                    accessibilityText: Localization.format("Currency, currently selected %@", selectedCurrency.localizedName)
                ) {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .settings, sheet: .currencySelector)
                    )
                    isSelectingCurrency = true
                }
                
                Separator()
                
                SettingsNavigationView(
                    title: "Language",
                    subTitle: selectedLanguage.settingsSubtitle,
                    accessibilityText: Localization.format("Language, currently selected %@", Localization.string(selectedLanguage.settingsSubtitle))
                ) {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .settings, sheet: .language)
                    )
                    isSelectingLanguage = true
                }
                
                Separator()
                
                SettingsNavigationView(
                    title: "Start Tab",
                    subTitle: selectedStartTab.rawValue,
                    accessibilityText: Localization.format("Start tab, currently selected %@", Localization.string(selectedStartTab.rawValue))
                ) {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .settings, sheet: .startTab)
                    )
                    isSelectingStartTab = true
                }
                
                Separator()
                
                SettingsNavigationView(
                    title: "Theme",
                    subTitle: appColorScheme.rawValue,
                    accessibilityText: Localization.format("Theme, currently selected %@", Localization.string(appColorScheme.rawValue))
                ) {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .settings, sheet: .theme)
                    )
                    isSelectingTheme = true
                }
                
                Separator()
                
                SettingsToggleLockedView(
                    title: "Live price updates",
                    subTitle: "See prices change on coin pages while you're viewing them",
                    isOn: webSocketEnabled
                ) {
                    if !webSocketEnabled && currentSubscription == nil {
                        navigationViewModel.showBuyPro = true
                        return
                    }
                    
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    webSocketEnabled.toggle()
                    SettingsManager.shared.set(data: webSocketEnabled, key: AppSettingKey.webSocketEnabled)

                    if webSocketEnabled {
                        AnalyticsManager.shared.log(
                            EnabledWebSocket(fromScreen: .settings)
                        )
                    } else {
                        AnalyticsManager.shared.log(
                            DisabledWebSocket(fromScreen: .settings)
                        )
                    }
                }
                
                Separator()
                
                SettingsToggleLockedView(
                    title: "Color blindness filter",
                    subTitle: "Uses blue and orange instead of green and red for price changes",
                    isOn: colorBlindnessFilterEnabled
                ) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    colorBlindnessFilterEnabled.toggle()
                    SettingsManager.shared.setColorBlindnessFilterEnabled(colorBlindnessFilterEnabled)
                    WidgetReloadService.shared.forceUpdateWidgets()
                    NotificationCenter.default.post(name: .colorBlindnessFilterChanged, object: nil)

                    if colorBlindnessFilterEnabled {
                        AnalyticsManager.shared.log(
                            EnabledColorBlindnessFilter(fromScreen: .settings)
                        )
                    } else {
                        AnalyticsManager.shared.log(
                            DisabledColorBlindnessFilter(fromScreen: .settings)
                        )
                    }
                }
            }
            .cardBackground()
        }
    }

    // MARK: - Tools
    
    @ViewBuilder
    private var toolsSettingsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionHeader(title: "Tools")
                .id(UUID())
            
            VStack(alignment: .leading, spacing: 16) {
                SettingsNavigationView(
                    title: "Converter",
                    accessibilityText: "Navigate to Converter"
                ) {
                    AnalyticsManager.shared.log(
                        Navigate(fromScreen: .settings, toScreen: .converter)
                    )
                    navigationViewModel.navPath.append(NavigationScreens.Converter)
                }
                
                Separator()
                
                SettingsNavigationView(
                    title: "Price Alerts",
                    accessibilityText: "Navigate to Price Alerts"
                ) {
                    AnalyticsManager.shared.log(
                        Navigate(fromScreen: .settings, toScreen: .priceAlerts)
                    )
                    navigationViewModel.navPath.append(NavigationScreens.PriceAlerts)
                }
            }
            .cardBackground()
        }
    }

    // MARK: - Security
    
    @ViewBuilder
    private var securityView: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionHeader(title: "Security")
                .id(UUID())
            
            VStack(alignment: .leading, spacing: 16) {
                SettingsToggleLockedView(
                    title: "Face ID / Touch ID",
                    subTitle: "Use Face ID / Touch ID to login",
                    isOn: isAuthenticationEnabled
                ) {
                    Task {
                        guard await !authViewModel.authenticate(toggling: true, forceAsk: true) else {
                            return
                        }
                        
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        isAuthenticationEnabled.toggle()
                        SettingsManager.shared.set(data: isAuthenticationEnabled, key: AppSettingKey.authenticationEnabled)

                        if isAuthenticationEnabled {
                            AnalyticsManager.shared.log(
                                EnabledFaceID(fromScreen: .settings)
                            )
                        } else {
                            AnalyticsManager.shared.log(
                                DisabledFaceID(fromScreen: .settings)
                            )
                        }
                    }
                }
                
                Separator()
                
                Button(action: {
                    AnalyticsManager.shared.log(
                        SheetOpened(fromScreen: .settings, sheet: .resetApp)
                    )
                    resetAppOpen = true
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Localization.string("Reset The App"))
                            .font(.satoshiBold(16))
                            .foregroundColor(.trendDown)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(Localization.string("Delete your settings and data"))
                            .font(.satoshiBold(12))
                            .foregroundStyle(Color.onSurfaceDimmer)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .combine)
                }
            }
            .cardBackground()
        }
    }
    
    // MARK: - Enjoy the app
    
    @ViewBuilder
    private var enjoyTheAppView: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionHeader(title: "Support")
                .id(UUID())
            
            VStack(alignment: .leading, spacing: 16) {
                SettingsImageView(
                    image: .appStore,
                    title: "Rate on App Store",
                    withExternalIcon: true
                ) {
                    if let url = URL(string: "itms-apps://apple.com/app/id1543974454") {
                        AnalyticsManager.shared.log(
                            WebViewOpened(fromScreen: .settings, url: url.absoluteString)
                        )
                        UIApplication.shared.open(url)
                    } else if let url = URL(string: "https://apps.apple.com/se/app/coincurrently/id1543974454#?platform=iphone") {
                        AnalyticsManager.shared.log(
                            WebViewOpened(fromScreen: .settings, url: url.absoluteString)
                        )
                        UIApplication.shared.open(url)
                    }
                }
                
                Separator()
                
                SettingsImageView(
                    image: .reddit,
                    title: "Follow on Reddit",
                    withExternalIcon: true
                ) {
                    if let url = URL(string: "https://www.reddit.com/r/coincurrently") {
                        AnalyticsManager.shared.log(
                            WebViewOpened(fromScreen: .settings, url: url.absoluteString)
                        )
                        UIApplication.shared.open(url)
                    }
                }
                
                Separator()
                
                SettingsImageView(
                    image: .x,
                    title: "Follow on X",
                    withExternalIcon: true
                ) {
                    if let url = URL(string: "https://twitter.com/CoinCurrently") {
                        AnalyticsManager.shared.log(
                            WebViewOpened(fromScreen: .settings, url: url.absoluteString)
                        )
                        UIApplication.shared.open(url)
                    }
                }
                
                Separator()
                
                SettingsImageView(
                    image: .share,
                    title: "Share the App"
                ) {
                    actionSheet()
                }

                Separator()
                
                SettingsImageView(
                    image: .feedback,
                    title: "Help us Improve",
                    accessibilityText: "Navigate to Help us improve",
                    withArrow: true,
                ) {
                    AnalyticsManager.shared.log(
                        Navigate(fromScreen: .settings, toScreen: .feedback)
                    )
                    navigationViewModel.navPath.append(.Feedback)
                }
            }
            .cardBackground()
        }
    }
    
    private var legalView: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionHeader(title: "Legal")
                .id(UUID())
            
            VStack(alignment: .leading, spacing: 16) {
                SettingsImageView(
                    image: nil,
                    title: "Terms and Conditions",
                    withExternalIcon: true
                ) {
                    if let url = URL(string: "https://coincurrently.app/terms") {
                        AnalyticsManager.shared.log(
                            WebViewOpened(fromScreen: .settings, url: url.absoluteString)
                        )
                        UIApplication.shared.open(url)
                    }
                }
                
                Separator()
                
                SettingsImageView(
                    image: nil,
                    title: "Privacy Policy",
                    withExternalIcon: true
                ) {
                    if let url = URL(string: "https://coincurrently.app/privacy") {
                        AnalyticsManager.shared.log(
                            WebViewOpened(fromScreen: .settings, url: url.absoluteString)
                        )
                        UIApplication.shared.open(url)
                    }
                }
            }
            .cardBackground()
        }
    }
    
    private var poweredView: some View {
        HStack(alignment: .center, spacing: 16) {
            Image("CoinGecko")
                .resizable()
                .scaledToFit()
                .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5), alignment: .center)
                .accessibilityHidden(true)

            Text(Localization.string("Powered by CoinGecko"))
                .font(.satoshiMedium(16))
                .foregroundStyle(Color.onSurfaceDimmer)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(Localization.string("Powered by coin gecko"))
        }
        .padding(.horizontal, 16)
    }

    private func actionSheet() {
        guard let iOSUrlShare = URL(string: "https://tinyurl.com/ygznuo76") else { return }
        guard let androidUrlShare = URL(string: "https://tinyurl.com/yz5w8ozj") else { return }
        let text = [
            Localization.string("Track crypto in real time with CoinCurrently."),
            Localization.string("Download the app for free."),
            Localization.format("iOS: %@", iOSUrlShare.absoluteString),
            Localization.format("Android: %@", androidUrlShare.absoluteString)
        ].joined(separator: "\n")

        let activityViewController = UIActivityViewController(activityItems: [ActivityControllerItemSource(title: "CoinCurrently", text: text)], applicationActivities: nil)

        activityViewController.completionWithItemsHandler = { activityType, completed, _, _ in
            let typeKey = activityType?.rawValue ?? "none"
            AnalyticsManager.shared.log(
                AppShareActivityCompleted(
                    fromScreen: .settings,
                    activityType: typeKey,
                    completed: completed
                )
            )
        }

        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = UIApplication.shared.window?.rootViewController?.view
            popoverController.sourceRect = CGRect(x: Int(UIApplication.shared.window?.rootViewController?.view.bounds.midX ?? 0),
                                                  y: Int(UIApplication.shared.window?.rootViewController?.view.bounds.minY ?? 0),
                                                  width: 0,
                                                  height: 0)
            popoverController.permittedArrowDirections = []
        }

        UIApplication.shared.window?.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }

    private func refreshCachedSections() async {
        let sortOption: SortOption = await CachedStorageManagerImp.shared.load(type: AppSettingKey.toplistSortOption.rawValue) ?? .mktCapDesc
        let priceChange: PriceChange = await CachedStorageManagerImp.shared.load(type: AppSettingKey.toplistPriceChange.rawValue) ?? .sevenDays
        
        await withTaskGroup { group in
            group.addTask {
                await ToplistRepositoryImp.shared.refreshForCurrencyChange(
                    sortOption: sortOption,
                    priceChange: priceChange
                )
            }
            group.addTask { await refreshHomeCachesWithSortSettings(priceChange: priceChange) }
            group.addTask { await refreshPortfolioCachesIfNeeded() }
        }
    }
    
    private func refreshIfCached<Element>(
        _ rows: [Element]?,
        _ refresh: () async -> Void
    ) async {
        guard let rows, !rows.isEmpty else { return }
        await refresh()
    }

    private func refreshHomeCachesWithSortSettings(priceChange: PriceChange) async {
        let winnersLosers = WinnersLosersRepositoryImp.shared

        await refreshIfCached(await winnersLosers.cachedWinnersCoins[priceChange.rawValue]?.data) {
            _ = await winnersLosers.getWinners(priceChange: priceChange)
        }

        await refreshIfCached(await winnersLosers.cachedLosersCoins[priceChange.rawValue]?.data) {
            _ = await winnersLosers.getLosers(priceChange: priceChange)
        }

        await refreshIfCached(await NewCoinsRepositoryImp.shared.cachedNewCoins?.data) {
            _ = await NewCoinsRepositoryImp.shared.getNewCoins()
        }
    }

    private func refreshPortfolioCachesIfNeeded() async {
        await refreshIfCached(await PortfolioRepositoryImp.shared.cachedPortfolioPies?.data) {
            _ = await PortfolioRepositoryImp.shared.getPortfolio()
            await CoreDataManager.shared.set(Date(), forKey: .walletRefreshDate)
            _ = await PortfolioRepositoryImp.shared.refreshWallets()
        }
    }
}
