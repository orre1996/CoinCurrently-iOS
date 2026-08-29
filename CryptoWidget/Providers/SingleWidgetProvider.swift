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
        await viewModel.fetchSnapshotEntry()
    }
    
    func timeline(for configuration: Intent, in context: Context) async -> Timeline<CryptoEntry> {
        let configured = await configuration.coinIDs(limit: 1)
        let ids = await WidgetCoinStorage.displayCoinIDs(
            configured: configured,
            limit: 1,
            requiresPro: context.family == .systemLarge
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
            
        case .systemMedium:
            MediumCryptoWidget(
                data: entry.cryptoInfos.first,
                image: entry.currencyLogos.first,
                selectedCurrency: entry.selectedCurrency
            )
            .widgetContainerBackground()
            
        case .systemLarge:
            LargeCryptoWidget(
                data: entry.cryptoInfos.first,
                image: entry.currencyLogos.first,
                selectedCurrency: entry.selectedCurrency,
                hasBoughtPro: entry.hasPro
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
                selectedCurrency: entry.selectedCurrency
            )
            .widgetBackground(Color.clear)
            
        case .accessoryRectangular:
            RectangularSingleCryptoWidget(
                data: entry.cryptoInfos.first,
                selectedCurrency: entry.selectedCurrency
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
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular, .systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
