//
//  MultiWidgetProvider.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2022-02-27.
//

import AppIntents
import Foundation
@preconcurrency import WidgetKit
import SwiftUI

struct MultiWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = CryptoEntry
    typealias Intent = MultiCoinWidgetConfigurationIntent
    
    private let viewModel = WidgetViewModelImp()
    
    func placeholder(in context: Context) -> CryptoEntry {
        CryptoEntry.empty()
    }
    
    func snapshot(for configuration: Intent, in context: Context) async -> CryptoEntry {
        if context.isPreview {
            return await viewModel.fetchSnapshotEntry()
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
        let configured = await configuration.coinIDs(limit: 6)
        return WidgetCoinStorage.displayCoinIDs(configured: configured, limit: 6)
    }
}

struct MultiWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var scheme
    
    let entry: Provider.Entry
    
    var body: some View {
        switch family {
        case .systemLarge:
            LargeMultiWidget(
                data: entry.cryptoInfos,
                image: entry.currencyLogos,
                selectedCurrency: entry.selectedCurrency,
                selectedCoinIDs: entry.selectedCoinIDs
            )
            .widgetContainerBackground()
            
        default:
            Text("")
                .widgetBackground(Color.clear)
        }
    }
}


struct MultiWidget: Widget {
    
    private let kind = "My_Multi_Widget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: MultiCoinWidgetConfigurationIntent.self,
            provider: MultiWidgetProvider(),
            content: { entry in
                MultiWidgetEntryView(entry: entry)
            })
            .configurationDisplayName("Multi widgets")
            .description("Track your favourite cryptocurrencies. All in one widget")
            .supportedFamilies([.systemLarge])
            .contentMarginsDisabled()
    }
}
