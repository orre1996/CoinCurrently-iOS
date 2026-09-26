//
//  CryptoWidget.swift
//  CryptoWidget
//
//  Created by Oscar Berggren on 2020-10-23.
//

import WidgetKit
import SwiftUI
import Intents
import AppIntents
import FirebaseCore
import RevenueCat

@main
struct MainWidgetBundle: WidgetBundle {

    init() {
        _ = WidgetConfigurationIntentRegistry.supportedIntents
        RevenueCatConfigurator.configureIfNeeded()
        
        Task {
            await WidgetViewModelImp().prefetchSnapshotCoins()
        }
    }

    @WidgetBundleBuilder
    var body: some Widget {
        AppShortcutWidget()
        SingleWidget()
        DuoWidget()
        QuadWidget()
        MultiWidget()
        RemainingWidgets().body
    }
}

struct RemainingWidgets: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        PortfolioWidget()
        NewsWidget()
        FearGreedWidget()
        TripleWidget()
    }
}
