//
//  WidgetConfigurationIntent.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 6/16/26.
//

import AppIntents
import Foundation

enum WidgetRefreshInterval {
    static let loaded: TimeInterval = 60 * 15
    static let retry: TimeInterval = 60 * 2
}

enum WidgetCoinStorage {
    private static let snapshotCoinLimit = 8

    static func coinIDs() async -> [String] {
        let coins: [Toplist]? = await CachedStorageManagerImp.shared.load(type: LocalStorageKeys.widgets)
        return coins?.compactMap(\.id).filter { !$0.isEmpty } ?? []
    }

    static func snapshotCoinIDs(limit: Int = snapshotCoinLimit) async -> [String] {
        await ToplistRepositoryImp.shared.ensureCacheLoaded()
        if let toplist = await ToplistRepositoryImp.shared.cachedSmallToplist?.data {
            let ids = toplist.compactMap(\.id).filter { !$0.isEmpty }
            if !ids.isEmpty {
                return Array(ids.prefix(limit))
            }
        }

        return Array(
            ["bitcoin", "ethereum", "solana", "tether", "binancecoin", "ripple", "usd-coin", "cardano"]
                .prefix(limit)
        )
    }

    static func displayCoinIDs(configured: [String], limit: Int) -> [String] {
        Array(configured.prefix(limit))
    }
}

struct CryptoWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "News Widget" }
    static var description: IntentDescription { IntentDescription("Keep track of the latest crypto news.") }

    init() {}
}

struct GasFeeWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Gas Fee Widget" }
    static var description: IntentDescription { IntentDescription("Display current gas fees.") }
}

struct FearGreedWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Fear and Greed Widget" }
    static var description: IntentDescription { IntentDescription("Display the fear and greed index.") }
}

struct SingleCoinWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Single Widget" }
    static var description: IntentDescription { IntentDescription("Choose a coin to display.") }

    @Parameter(
        title: "First Coin",
        requestValueDialog: IntentDialog("Choose")
    )
    var coin: CoinEntity?

    init() {
        coin = nil
    }

    init(coin: CoinEntity?) {
        self.coin = coin
    }

    func coinIDs(limit: Int = 1) async -> [String] {
        if let id = coin?.id, !id.isEmpty {
            return Array([id].prefix(limit))
        }
        return []
    }
}

struct DuoCoinWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Duo Widget" }
    static var description: IntentDescription { IntentDescription("Choose two coins to display.") }

    @Parameter(
        title: "First Coin",
        requestValueDialog: IntentDialog("Choose")
    )
    var firstCoin: CoinEntity?

    @Parameter(
        title: "Second Coin",
        requestValueDialog: IntentDialog("Choose")
    )
    var secondCoin: CoinEntity?

    init() {
        firstCoin = nil
        secondCoin = nil
    }

    init(firstCoin: CoinEntity?, secondCoin: CoinEntity?) {
        self.firstCoin = firstCoin
        self.secondCoin = secondCoin
    }

    func coinIDs(limit: Int = 2) async -> [String] {
        let configured = [firstCoin?.id, secondCoin?.id].compactMap { $0 }.filter { !$0.isEmpty }
        return Array(configured.prefix(limit))
    }
}

struct QuadCoinWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Quad Widget" }
    static var description: IntentDescription { IntentDescription("Choose four coins to display.") }

    @Parameter(title: "First Coin")
    var firstCoin: CoinEntity?

    @Parameter(title: "Second Coin")
    var secondCoin: CoinEntity?

    @Parameter(title: "Third Coin")
    var thirdCoin: CoinEntity?

    @Parameter(title: "Fourth Coin")
    var fourthCoin: CoinEntity?

    init() {
        firstCoin = nil
        secondCoin = nil
        thirdCoin = nil
        fourthCoin = nil
    }

    func coinIDs(limit: Int = 4) async -> [String] {
        let configured = [firstCoin?.id, secondCoin?.id, thirdCoin?.id, fourthCoin?.id]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return Array(configured.prefix(limit))
    }
}

struct TripleCoinWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Triple Widget" }
    static var description: IntentDescription { IntentDescription("Choose three coins to display.") }

    @Parameter(
        title: "First Coin",
        requestValueDialog: IntentDialog("Choose")
    )
    var firstCoin: CoinEntity?

    @Parameter(
        title: "Second Coin",
        requestValueDialog: IntentDialog("Choose")
    )
    var secondCoin: CoinEntity?

    @Parameter(
        title: "Third Coin",
        requestValueDialog: IntentDialog("Choose")
    )
    var thirdCoin: CoinEntity?

    init() {
        firstCoin = nil
        secondCoin = nil
        thirdCoin = nil
    }

    func coinIDs(limit: Int = 3) async -> [String] {
        let configured = [firstCoin?.id, secondCoin?.id, thirdCoin?.id]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return Array(configured.prefix(limit))
    }
}

struct MultiCoinWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Multi Widget" }
    static var description: IntentDescription { IntentDescription("Choose coins to display.") }

    @Parameter(
        title: "First Coin",
        requestValueDialog: IntentDialog("Choose")
    )
    var firstCoin: CoinEntity?

    @Parameter(
        title: "Second Coin",
        requestValueDialog: IntentDialog("Choose")
    )
    var secondCoin: CoinEntity?

    @Parameter(
        title: "Third Coin",
        requestValueDialog: IntentDialog("Choose")
    )
    var thirdCoin: CoinEntity?

    @Parameter(
        title: "Fourth Coin",
        requestValueDialog: IntentDialog("Choose")
    )
    var fourthCoin: CoinEntity?

    @Parameter(
        title: "Fifth Coin",
        requestValueDialog: IntentDialog("Choose")
    )
    var fifthCoin: CoinEntity?

    @Parameter(
        title: "Sixth Coin",
        requestValueDialog: IntentDialog("Choose")
    )
    var sixthCoin: CoinEntity?

    init() {
        firstCoin = nil
        secondCoin = nil
        thirdCoin = nil
        fourthCoin = nil
        fifthCoin = nil
        sixthCoin = nil
    }

    func coinIDs(limit: Int) async -> [String] {
        let configured = [
            firstCoin?.id,
            secondCoin?.id,
            thirdCoin?.id,
            fourthCoin?.id,
            fifthCoin?.id,
            sixthCoin?.id
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        return Array(configured.prefix(limit))
    }
}

enum WidgetConfigurationIntentRegistry {
    static let supportedIntents: [any AppIntent.Type] = [
        CryptoWidgetConfigurationIntent.self,
        SingleCoinWidgetConfigurationIntent.self,
        DuoCoinWidgetConfigurationIntent.self,
        QuadCoinWidgetConfigurationIntent.self,
        TripleCoinWidgetConfigurationIntent.self,
        MultiCoinWidgetConfigurationIntent.self,
        GasFeeWidgetConfigurationIntent.self,
        FearGreedWidgetConfigurationIntent.self
    ]
}
