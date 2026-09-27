//
//  SingleWidgetProvider.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2020-11-06.
//

import AppIntents
import SwiftUI
@preconcurrency import WidgetKit

struct Provider: AppIntentTimelineProvider {
    typealias Entry = CryptoEntry
    typealias Intent = SingleCoinWidgetConfigurationIntent
    
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
        let configured = await configuration.coinIDs(limit: 1)
        return WidgetCoinStorage.displayCoinIDs(configured: configured, limit: 1)
    }
}

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var scheme

    let entry: Provider.Entry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallCryptoWidget(
                data: entry.cryptoInfos.first,
                image: entry.currencyLogos.first,
                selectedCurrency: entry.selectedCurrency,
                coinID: entry.selectedCoinIDs.first
            )
            .widgetContainerBackground()
            
        case .accessoryInline:
            InlineCryptoWidget(
                data: entry.cryptoInfos.first,
                selectedCurrency: entry.selectedCurrency
            )
            .widgetBackground(Color.clear)
            
        case .accessoryCircular:
            CircularCryptoWidget(
                data: entry.cryptoInfos.first,
                selectedCurrency: entry.selectedCurrency,
                coinID: entry.selectedCoinIDs.first
            )
            .widgetBackground(Color.clear)
            
        default:
            Text("")
                .widgetBackground(Color.clear)
        }
    }
}


struct SingleWidget: Widget {
    
    private let kind = "My_Widget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SingleCoinWidgetConfigurationIntent.self,
            provider: Provider(),
            content: { entry in
                WidgetEntryView(entry: entry)
            })
        .configurationDisplayName("Single widgets")
        .description("Track your favourite cryptocurrency. All in one widget")
        .supportedFamilies([.systemSmall, .accessoryInline, .accessoryCircular])
        .contentMarginsDisabled()
    }
}
