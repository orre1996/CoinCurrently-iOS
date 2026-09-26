//
//  DuoWidgetProvider.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2020-11-06.
//

import AppIntents
import Foundation
@preconcurrency import WidgetKit
import SwiftUI

struct DuoWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = CryptoEntry
    typealias Intent = DuoCoinWidgetConfigurationIntent
    
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
        let configured = await configuration.coinIDs(limit: 2)
        return WidgetCoinStorage.displayCoinIDs(configured: configured, limit: 2)
    }
}

struct DuoWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var scheme
    
    let entry: CryptoEntry
    
    var body: some View {
        switch family {
        case .systemMedium:
            MediumDuoWidget(
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


struct DuoWidget: Widget {
    
    private let kind = "CoinCurrently_Duo_Widget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: DuoCoinWidgetConfigurationIntent.self,
            provider: DuoWidgetProvider(),
            content: { entry in
                DuoWidgetEntryView(entry: entry)
            }
        )
        .configurationDisplayName("Duo widgets")
        .description("Track your favourite cryptocurrencies. All in one widget")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}
