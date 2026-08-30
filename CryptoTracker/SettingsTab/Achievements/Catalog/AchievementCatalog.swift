//
//  AchievementCatalog.swift
//  CoinCurrently
//

import Foundation

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        dailyDevotee,
        watchlistWatcher,
        portfolioPioneer,
        portfolioExporter,
        moonShot,
        alertAce,
        widgetWizard,
        searchSavant,
        marketExplorer,
        compareMaster,
        newsReader,
        nftNavigator,
        exchangeExpert,
        sectorScout,
        fearGreedFollower,
        gasTracker,
        treasuryTracker,
        chartAnalyst,
        converterPro,
        securitySentinel,
        referralChampion,
        imATeapot
    ]

    static func achievements(in category: AchievementCategory) -> [AchievementDefinition] {
        all.filter { $0.category == category }
    }

    // MARK: - Streaks

    private static let dailyDevotee = AchievementDefinition(
        id: "daily_devotee",
        title: "Daily Devotee",
        description: "Open the app on consecutive days",
        category: .streaks,
        icon: "flame.fill",
        metric: .dailyStreak,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 1, description: "1 day streak"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 3, description: "3 day streak"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 7, description: "7 day streak"),
            AchievementLevel(name: AchievementLevelTier.platinum, threshold: 14, description: "14 day streak"),
            AchievementLevel(name: AchievementLevelTier.diamond, threshold: 30, description: "30 day streak"),
            AchievementLevel(name: AchievementLevelTier.master, threshold: 60, description: "60 day streak"),
            AchievementLevel(name: "Legend", threshold: 90, description: "90 day streak")
        ],
        valueFormat: .integer
    )

    // MARK: - Portfolio

    private static let portfolioPioneer = AchievementDefinition(
        id: "portfolio_pioneer",
        title: "Portfolio Pioneer",
        description: "Add transactions to your portfolio",
        category: .portfolio,
        icon: "chart.pie.fill",
        metric: .portfolioTransactions,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 1, description: "1 transaction"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 3, description: "3 transactions"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 5, description: "5 transactions"),
            AchievementLevel(name: AchievementLevelTier.platinum, threshold: 10, description: "10 transactions"),
            AchievementLevel(name: AchievementLevelTier.diamond, threshold: 25, description: "25 transactions"),
            AchievementLevel(name: AchievementLevelTier.master, threshold: 50, description: "50 transactions")
        ],
        valueFormat: .integer
    )

    private static let portfolioExporter = AchievementDefinition(
        id: "portfolio_exporter",
        title: "Portfolio Exporter",
        description: "Export your portfolio",
        category: .portfolio,
        icon: "square.and.arrow.up",
        metric: .portfolioExports,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 1, description: "1 export"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 3, description: "3 exports"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 5, description: "5 exports"),
            AchievementLevel(name: AchievementLevelTier.platinum, threshold: 10, description: "10 exports"),
            AchievementLevel(name: AchievementLevelTier.diamond, threshold: 25, description: "25 exports")
        ],
        valueFormat: .integer
    )

    private static let moonShot = AchievementDefinition(
        id: "moon_shot",
        title: "Moon Shot",
        description: "Have a portfolio coin up by a big percentage",
        category: .portfolio,
        icon: "arrow.up.right.circle.fill",
        metric: .maxPortfolioGainPercent,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 50, description: "Up 50%"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 100, description: "Up 100%"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 200, description: "Up 200%"),
            AchievementLevel(name: AchievementLevelTier.platinum, threshold: 500, description: "Up 500%"),
            AchievementLevel(name: AchievementLevelTier.diamond, threshold: 1000, description: "Up 1000%")
        ],
        valueFormat: .percent
    )

    // MARK: - Favorites

    private static let watchlistWatcher = AchievementDefinition(
        id: "watchlist_watcher",
        title: "Watchlist Watcher",
        description: "Add coins to your favorites",
        category: .favorites,
        icon: "star.fill",
        metric: .favoritesCount,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 1, description: "1 favorite"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 3, description: "3 favorites"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 5, description: "5 favorites"),
            AchievementLevel(name: AchievementLevelTier.platinum, threshold: 10, description: "10 favorites"),
            AchievementLevel(name: AchievementLevelTier.diamond, threshold: 25, description: "25 favorites")
        ],
        valueFormat: .integer
    )

    // MARK: - Tools

    private static let alertAce = AchievementDefinition(
        id: "alert_ace",
        title: "Alert Ace",
        description: "Create price alerts",
        category: .tools,
        icon: "bell.fill",
        metric: .priceAlertsCount,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 1, description: "1 alert"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 2, description: "2 alerts"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 3, description: "3 alerts"),
            AchievementLevel(name: AchievementLevelTier.platinum, threshold: 5, description: "5 alerts"),
            AchievementLevel(name: AchievementLevelTier.diamond, threshold: 10, description: "10 alerts"),
            AchievementLevel(name: AchievementLevelTier.master, threshold: 20, description: "20 alerts")
        ],
        valueFormat: .integer
    )

    private static let widgetWizard = AchievementDefinition(
        id: "widget_wizard",
        title: "Widget Wizard",
        description: "Add coins to your widgets",
        category: .tools,
        icon: "square.grid.2x2.fill",
        metric: .widgetCoinsCount,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 1, description: "1 widget coin"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 2, description: "2 widget coins"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 4, description: "4 widget coins"),
            AchievementLevel(name: AchievementLevelTier.platinum, threshold: 8, description: "8 widget coins")
        ],
        valueFormat: .integer
    )

    private static let converterPro = AchievementDefinition(
        id: "converter_pro",
        title: "Converter Pro",
        description: "Use the currency converter",
        category: .tools,
        icon: "function",
        metric: .converterUses,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 1, description: "1 conversion"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 10, description: "10 conversions"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 50, description: "50 conversions"),
            AchievementLevel(name: AchievementLevelTier.platinum, threshold: 100, description: "100 conversions")
        ],
        valueFormat: .integer
    )

    private static let chartAnalyst = AchievementDefinition(
        id: "chart_analyst",
        title: "Chart Analyst",
        description: "Switch between chart types",
        category: .tools,
        icon: "chart.xyaxis.line",
        metric: .candleChartToggles,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 1, description: "1 toggle"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 10, description: "10 toggles"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 50, description: "50 toggles")
        ],
        valueFormat: .integer
    )

    // MARK: - Explorer

    private static let searchSavant = AchievementDefinition(
        id: "search_savant",
        title: "Search Savant",
        description: "Search for unique coins and assets",
        category: .explorer,
        icon: "magnifyingglass",
        metric: .uniqueSearches,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 5, description: "5 unique searches"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 10, description: "10 unique searches"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 25, description: "25 unique searches"),
            AchievementLevel(name: AchievementLevelTier.platinum, threshold: 50, description: "50 unique searches"),
            AchievementLevel(name: AchievementLevelTier.diamond, threshold: 100, description: "100 unique searches")
        ],
        valueFormat: .integer
    )

    private static let marketExplorer = AchievementDefinition(
        id: "market_explorer",
        title: "Market Explorer",
        description: "View coin detail pages",
        category: .explorer,
        icon: "bitcoinsign.circle.fill",
        metric: .cryptoDetailsViewed,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 5, description: "5 coins viewed"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 25, description: "25 coins viewed"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 100, description: "100 coins viewed"),
            AchievementLevel(name: AchievementLevelTier.platinum, threshold: 500, description: "500 coins viewed")
        ],
        valueFormat: .integer
    )

    private static let compareMaster = AchievementDefinition(
        id: "compare_master",
        title: "Compare Master",
        description: "Compare coins side by side",
        category: .explorer,
        icon: "arrow.left.arrow.right",
        metric: .compareSessions,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 1, description: "1 compare session"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 5, description: "5 compare sessions"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 15, description: "15 compare sessions"),
            AchievementLevel(name: AchievementLevelTier.platinum, threshold: 50, description: "50 compare sessions")
        ],
        valueFormat: .integer
    )

    private static let newsReader = AchievementDefinition(
        id: "news_reader",
        title: "News Reader",
        description: "Read crypto news articles",
        category: .explorer,
        icon: "newspaper.fill",
        metric: .newsArticlesOpened,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 5, description: "5 articles"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 25, description: "25 articles"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 100, description: "100 articles"),
            AchievementLevel(name: AchievementLevelTier.platinum, threshold: 500, description: "500 articles")
        ],
        valueFormat: .integer
    )

    private static let nftNavigator = AchievementDefinition(
        id: "nft_navigator",
        title: "NFT Navigator",
        description: "Explore NFT collections",
        category: .explorer,
        icon: "photo.artframe",
        metric: .nftDetailsViewed,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 1, description: "1 NFT viewed"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 5, description: "5 NFTs viewed"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 15, description: "15 NFTs viewed"),
            AchievementLevel(name: AchievementLevelTier.platinum, threshold: 50, description: "50 NFTs viewed")
        ],
        valueFormat: .integer
    )

    private static let exchangeExpert = AchievementDefinition(
        id: "exchange_expert",
        title: "Exchange Expert",
        description: "View exchange detail pages",
        category: .explorer,
        icon: "building.columns.fill",
        metric: .exchangeDetailsViewed,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 1, description: "1 exchange viewed"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 5, description: "5 exchanges viewed"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 15, description: "15 exchanges viewed")
        ],
        valueFormat: .integer
    )

    private static let sectorScout = AchievementDefinition(
        id: "sector_scout",
        title: "Sector Scout",
        description: "Browse crypto sectors",
        category: .explorer,
        icon: "square.grid.3x3.fill",
        metric: .sectorDetailsViewed,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 1, description: "1 sector viewed"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 5, description: "5 sectors viewed"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 15, description: "15 sectors viewed")
        ],
        valueFormat: .integer
    )

    private static let fearGreedFollower = AchievementDefinition(
        id: "fear_greed_follower",
        title: "Fear & Greed Follower",
        description: "Check the Fear & Greed Index",
        category: .explorer,
        icon: "gauge.with.needle.fill",
        metric: .fearGreedVisits,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 1, description: "1 visit"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 7, description: "7 visits"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 30, description: "30 visits")
        ],
        valueFormat: .integer
    )

    private static let gasTracker = AchievementDefinition(
        id: "gas_tracker",
        title: "Gas Tracker",
        description: "Check Ethereum gas fees",
        category: .explorer,
        icon: "fuelpump.fill",
        metric: .gasFeesVisits,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 1, description: "1 visit"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 7, description: "7 visits"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 30, description: "30 visits")
        ],
        valueFormat: .integer
    )

    private static let treasuryTracker = AchievementDefinition(
        id: "treasury_tracker",
        title: "Treasury Tracker",
        description: "Explore corporate crypto treasuries",
        category: .explorer,
        icon: "banknote.fill",
        metric: .treasuryVisits,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 1, description: "1 visit"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 5, description: "5 visits"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 15, description: "15 visits")
        ],
        valueFormat: .integer
    )

    // MARK: - Security

    private static let securitySentinel = AchievementDefinition(
        id: "security_sentinel",
        title: "Security Sentinel",
        description: "Enable Face ID or Touch ID",
        category: .security,
        icon: "faceid",
        metric: .authenticationEnabled,
        levels: [
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 1, description: "Face ID enabled")
        ],
        valueFormat: .boolean
    )

    private static let referralChampion = AchievementDefinition(
        id: "referral_champion",
        title: "Referral Champion",
        description: "Refer friends to CoinCurrently",
        category: .security,
        icon: "person.2.fill",
        metric: .referralsCompleted,
        levels: [
            AchievementLevel(name: AchievementLevelTier.bronze, threshold: 1, description: "1 referral"),
            AchievementLevel(name: AchievementLevelTier.silver, threshold: 2, description: "2 referrals"),
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 3, description: "3 referrals")
        ],
        valueFormat: .integer
    )

    private static let imATeapot = AchievementDefinition(
        id: "418_im_a_teapot",
        title: "418 I'm a teapot",
        description: "Try to redeem your own referral code",
        category: .security,
        icon: "cup.and.saucer.fill",
        metric: .selfRedeems,
        levels: [
            AchievementLevel(name: AchievementLevelTier.gold, threshold: 1, description: "Tried to redeem yourself")
        ],
        valueFormat: .boolean
    )
}
