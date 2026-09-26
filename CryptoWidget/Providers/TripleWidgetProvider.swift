//
//  TripleWidgetProvider.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2026-09-25.
//

import AppIntents
import Foundation
@preconcurrency import WidgetKit
import SwiftUI

struct TripleWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = CryptoEntry
    typealias Intent = TripleCoinWidgetConfigurationIntent
    
    private let viewModel = WidgetViewModelImp()
    
    func placeholder(in context: Context) -> CryptoEntry {
        CryptoEntry.empty()
    }
    
    func snapshot(for configuration: Intent, in context: Context) async -> CryptoEntry {
        if context.isPreview {
            return await viewModel.fetchSnapshotEntry(limit: 3)
        }

        let ids = await displayCoinIDs(for: configuration)
        return await viewModel.fetchDisplayEntry(ids: ids)
    }
    
    func timeline(for configuration: Intent, in _: Context) async -> Timeline<CryptoEntry> {
        let ids = await displayCoinIDs(for: configuration)
        let entry = await viewModel.fetchDisplayEntry(ids: ids)
        let interval = ids.isEmpty ? WidgetRefreshInterval.retry : WidgetRefreshInterval.loaded
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(interval)))
    }

    private func displayCoinIDs(for configuration: Intent) async -> [String] {
        let configured = await configuration.coinIDs(limit: 3)
        return WidgetCoinStorage.displayCoinIDs(configured: configured, limit: 3)
    }
}

struct TripleWidgetEntryView: View {
    let entry: TripleWidgetProvider.Entry
    
    var body: some View {
        RectangularMultiCryptoWidget(
            data: entry.cryptoInfos,
            selectedCurrency: entry.selectedCurrency,
            selectedCoinIDs: entry.selectedCoinIDs
        )
        .widgetBackground(Color.clear)
    }
}

struct TripleWidget: Widget {
    private let kind = "My_Triple_Widget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: TripleCoinWidgetConfigurationIntent.self,
            provider: TripleWidgetProvider(),
            content: { entry in
                TripleWidgetEntryView(entry: entry)
            }
        )
        .configurationDisplayName("Triple widgets")
        .description("Track your favourite cryptocurrencies. All in one widget")
        .supportedFamilies([.accessoryRectangular])
        .contentMarginsDisabled()
    }
}
