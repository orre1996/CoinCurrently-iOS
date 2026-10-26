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

@main
struct MainWidgetBundle: WidgetBundle {

    init() {
        _ = WidgetConfigurationIntentRegistry.supportedIntents

        Task {
            await WidgetViewModelImp().prefetchSnapshotCoins()
        }
    }

    @WidgetBundleBuilder
    var body: some Widget {
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
        FearGreedWidget()
        TripleWidget()
    }
}
