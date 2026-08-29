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

private enum WidgetExtensionBootstrap {
    static func configure() {
        RevenueCatConfigurator.configureIfNeeded()
    }

    static func warmUp() {
        Task {
            await WidgetViewModelImp().prefetchSnapshotCoins()
        }
    }
}

@main
struct MyWidgetBundle: WidgetBundle {

    init() {
        _ = WidgetConfigurationIntentRegistry.supportedIntents
        WidgetExtensionBootstrap.configure()
        WidgetExtensionBootstrap.warmUp()
    }

    @WidgetBundleBuilder
    var body: some Widget {
        SingleWidget()
        DuoWidget()
        QuadWidget()
        MyWidgetBundle1().body
    }
}

struct MyWidgetBundle1: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        MultiWidget()
        PortfolioWidget()
        NewsWidget()
        MyWidgetBundle2().body
    }
}

struct MyWidgetBundle2: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        FearGreedWidget()
        GasFeesWidget()
    }
}
