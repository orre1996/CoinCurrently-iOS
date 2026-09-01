//
//  CoinCurrentlyAppIntents.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-06-01.
//

#if IS_APP
import AppIntents

struct OpenHomeIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Home" }
    static var description: IntentDescription { IntentDescription("Opens the home tab.") }
    static var openAppWhenRun: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        SiriNavigationManager.navigate(to: "home")
        return .result()
    }
}

struct OpenPortfolioIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Portfolio" }
    static var description: IntentDescription { IntentDescription("Opens your crypto portfolio.") }
    static var openAppWhenRun: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        SiriNavigationManager.navigate(to: "portfolio")
        return .result()
    }
}

struct OpenMarketIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Market" }
    static var description: IntentDescription { IntentDescription("Opens the market tab.") }
    static var openAppWhenRun: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        SiriNavigationManager.navigate(to: "marketTab")
        return .result()
    }
}

struct OpenNewsIntent: AppIntent {
    static var title: LocalizedStringResource { "Open News" }
    static var description: IntentDescription { IntentDescription("Opens crypto news.") }
    static var openAppWhenRun: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        SiriNavigationManager.navigate(to: "news")
        return .result()
    }
}

struct OpenSettingsIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Settings" }
    static var description: IntentDescription { IntentDescription("Opens app settings.") }
    static var openAppWhenRun: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        SiriNavigationManager.navigate(to: "settings")
        return .result()
    }
}

struct OpenFearGreedIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Fear and Greed Index" }
    static var description: IntentDescription { IntentDescription("Opens the crypto fear and greed index.") }
    static var openAppWhenRun: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        SiriNavigationManager.navigate(to: "fearGreed")
        return .result()
    }
}

struct OpenPriceAlertsIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Price Alerts" }
    static var description: IntentDescription { IntentDescription("Opens your price alerts.") }
    static var openAppWhenRun: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        SiriNavigationManager.navigate(to: "priceAlerts")
        return .result()
    }
}

struct OpenGasFeesIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Gas Fees" }
    static var description: IntentDescription { IntentDescription("Opens current gas fees.") }
    static var openAppWhenRun: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        SiriNavigationManager.navigate(to: "gasFees")
        return .result()
    }
}

struct OpenBitcoinIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Bitcoin" }
    static var description: IntentDescription { IntentDescription("Opens Bitcoin price and details.") }
    static var openAppWhenRun: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        SiriNavigationManager.navigate(to: "bitcoin,BTC")
        return .result()
    }
}

struct OpenEthereumIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Ethereum" }
    static var description: IntentDescription { IntentDescription("Opens Ethereum price and details.") }
    static var openAppWhenRun: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        SiriNavigationManager.navigate(to: "ethereum,ETH")
        return .result()
    }
}

struct CoinCurrentlyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenHomeIntent(),
            phrases: [
                "Open home in \(.applicationName)",
                "Go to home in \(.applicationName)"
            ],
            shortTitle: "Home",
            systemImageName: "house"
        )
        
        AppShortcut(
            intent: OpenPortfolioIntent(),
            phrases: [
                "Open portfolio in \(.applicationName)",
                "Show my portfolio in \(.applicationName)"
            ],
            shortTitle: "Portfolio",
            systemImageName: "chart.pie"
        )
        
        AppShortcut(
            intent: OpenMarketIntent(),
            phrases: [
                "Open market in \(.applicationName)",
                "Show the market in \(.applicationName)"
            ],
            shortTitle: "Market",
            systemImageName: "chart.line.uptrend.xyaxis"
        )
        
        AppShortcut(
            intent: OpenNewsIntent(),
            phrases: [
                "Open news in \(.applicationName)",
                "Show crypto news in \(.applicationName)"
            ],
            shortTitle: "News",
            systemImageName: "newspaper"
        )
        
        AppShortcut(
            intent: OpenSettingsIntent(),
            phrases: [
                "Open settings in \(.applicationName)",
                "Go to settings in \(.applicationName)"
            ],
            shortTitle: "Settings",
            systemImageName: "gearshape"
        )
        
        AppShortcut(
            intent: OpenFearGreedIntent(),
            phrases: [
                "Open fear and greed in \(.applicationName)",
                "Show fear and greed index in \(.applicationName)"
            ],
            shortTitle: "Fear & Greed",
            systemImageName: "gauge.with.needle"
        )
        
        AppShortcut(
            intent: OpenPriceAlertsIntent(),
            phrases: [
                "Open price alerts in \(.applicationName)",
                "Show my price alerts in \(.applicationName)"
            ],
            shortTitle: "Price Alerts",
            systemImageName: "bell"
        )
        
        AppShortcut(
            intent: OpenGasFeesIntent(),
            phrases: [
                "Open gas fees in \(.applicationName)",
                "Show gas fees in \(.applicationName)"
            ],
            shortTitle: "Gas Fees",
            systemImageName: "fuelpump"
        )
        
        AppShortcut(
            intent: OpenBitcoinIntent(),
            phrases: [
                "Show Bitcoin in \(.applicationName)",
                "Open Bitcoin in \(.applicationName)",
                "Show BTC in \(.applicationName)"
            ],
            shortTitle: "Bitcoin",
            systemImageName: "bitcoinsign.circle.fill"
        )
        
        AppShortcut(
            intent: OpenEthereumIntent(),
            phrases: [
                "Show Ethereum in \(.applicationName)",
                "Open Ethereum in \(.applicationName)",
                "Show ETH in \(.applicationName)"
            ],
            shortTitle: "Ethereum",
            systemImageName: "e.circle.fill"
        )
    }
}
#endif
