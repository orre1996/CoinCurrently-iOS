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
        await viewModel.fetchSnapshotEntry()
    }
    
    func timeline(for configuration: Intent, in context: Context) async -> Timeline<CryptoEntry> {
        let configured = await configuration.coinIDs(limit: 4)
        let ids = await WidgetCoinStorage.displayCoinIDs(
            configured: configured,
            limit: 4,
            requiresPro: true
        )
        return await withCheckedContinuation { continuation in
            viewModel.getCoinsWithSparkline(ids: ids) { result in
                switch result {
                case .success(let entry):
                    let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * (entry.hasPro ? 3 : 15))))
                    continuation.resume(returning: timeline)
                case .failure(_):
                    let timeline = Timeline(entries: [CryptoEntry.empty(selectedCoinIDs: ids)], policy: .after(Date().addingTimeInterval(60 * 2)))
                    continuation.resume(returning: timeline)
                }
            }
        }
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
