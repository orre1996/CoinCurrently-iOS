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

        let ids = await displayCoinIDs(for: configuration, family: context.family)
        return await viewModel.fetchDisplayEntry(ids: ids)
    }
    
    func timeline(for configuration: Intent, in context: Context) async -> Timeline<CryptoEntry> {
        let ids = await displayCoinIDs(for: configuration, family: context.family)
        let entry = await viewModel.fetchDisplayEntry(ids: ids)
        let minutes = ids.isEmpty ? 2.0 : (entry.hasPro ? 3.0 : 15.0)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * minutes)))
    }

    private func displayCoinIDs(for configuration: Intent, family: WidgetFamily) async -> [String] {
        let limit = WidgetCoinStorage.multiWidgetCoinLimit(for: family)
        let configured = await configuration.coinIDs(limit: limit)
        return await WidgetCoinStorage.displayCoinIDs(
            configured: configured,
            limit: limit,
            requiresPro: Self.requiresPro(for: family)
        )
    }

    private static func requiresPro(for family: WidgetFamily) -> Bool {
        switch family {
        case .systemMedium, .systemLarge, .accessoryRectangular: return true
        default: return false
        }
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
                selectedCoinIDs: entry.selectedCoinIDs,
                hasBoughtPro: entry.hasPro
            )
            .widgetContainerBackground()
            
        case .accessoryRectangular:
            RectangularCryptoWidget(
                data: entry.cryptoInfos,
                selectedCurrency: entry.selectedCurrency,
                hasBoughtPro: entry.hasPro
            )
            .widgetBackground(Color.clear)
            
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
            .supportedFamilies([.accessoryRectangular, .systemLarge])
            .contentMarginsDisabled()
    }
}
