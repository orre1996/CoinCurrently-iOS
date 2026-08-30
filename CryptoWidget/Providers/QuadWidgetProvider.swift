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

struct QuadWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = CryptoEntry
    typealias Intent = QuadCoinWidgetConfigurationIntent
    
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
    
    func timeline(for configuration: Intent, in context: Context) async -> Timeline<CryptoEntry> {
        let ids = await displayCoinIDs(for: configuration)
        let entry = await viewModel.fetchDisplayEntry(ids: ids)
        let minutes = ids.isEmpty ? 2.0 : (entry.hasPro ? 3.0 : 15.0)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * minutes)))
    }

    private func displayCoinIDs(for configuration: Intent) async -> [String] {
        let configured = await configuration.coinIDs(limit: 4)
        return await WidgetCoinStorage.displayCoinIDs(
            configured: configured,
            limit: 4,
            requiresPro: true
        )
    }
}

struct QuadWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var scheme

    let entry: Provider.Entry
    
    var body: some View {
        switch family {
        case .systemLarge:
            LargeQuadWidget(
                data: entry.cryptoInfos,
                image: entry.currencyLogos,
                selectedCurrency: entry.selectedCurrency,
                selectedCoinIDs: entry.selectedCoinIDs,
                hasBoughtPro: entry.hasPro
            )
            .widgetContainerBackground()
            
        default:
            Text("")
                .widgetBackground(Color.clear)
        }
    }
}


struct QuadWidget: Widget {
    
    private let kind = "My_Quad_Widget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: QuadCoinWidgetConfigurationIntent.self,
            provider: QuadWidgetProvider(),
            content: { entry in
                QuadWidgetEntryView(entry: entry)
            })
            .configurationDisplayName("Quad widgets")
            .description("Track your favourite cryptocurrencies. All in one widget")
            .supportedFamilies([.systemLarge])
            .contentMarginsDisabled()
    }
}
