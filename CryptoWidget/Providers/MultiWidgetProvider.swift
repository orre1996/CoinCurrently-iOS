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
        await viewModel.fetchSnapshotEntry()
    }
    
    func timeline(for configuration: Intent, in context: Context) async -> Timeline<CryptoEntry> {
        let limit = WidgetCoinStorage.multiWidgetCoinLimit(for: context.family)
        let configured = await configuration.coinIDs(limit: limit)
        let ids = await WidgetCoinStorage.displayCoinIDs(
            configured: configured,
            limit: limit,
            requiresPro: Self.requiresPro(for: context.family)
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
        case .systemSmall:
            SmallMultiWidget(
                data: entry.cryptoInfos,
                image: entry.currencyLogos,
                selectedCurrency: entry.selectedCurrency
            )
            .widgetContainerBackground()
            
        case .systemMedium:
            MediumMultiWidget(
                data: entry.cryptoInfos,
                image: entry.currencyLogos,
                selectedCurrency: entry.selectedCurrency,
                hasBoughtPro: entry.hasPro
            )
            .widgetContainerBackground()
            
        case .systemLarge:
            LargeMultiWidget(
                data: entry.cryptoInfos,
                image: entry.currencyLogos,
                selectedCurrency: entry.selectedCurrency,
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
            .supportedFamilies([.accessoryRectangular, .systemSmall, .systemMedium, .systemLarge])
            .contentMarginsDisabled()
    }
}
