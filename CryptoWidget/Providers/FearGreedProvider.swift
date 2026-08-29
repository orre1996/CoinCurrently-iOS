//
//  FearGreedProvider.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2022-02-28.
//

import AppIntents
import Foundation
@preconcurrency import WidgetKit
import SwiftUI

struct FearGreedProvider: AppIntentTimelineProvider {
    typealias Entry = FearGreedEntry
    typealias Intent = CryptoWidgetConfigurationIntent
    
    private let viewModel = WidgetViewModelImp()
    
    func placeholder(in context: Context) -> FearGreedEntry {
        FearGreedEntry.empty()
    }
    
    func snapshot(for configuration: Intent, in context: Context) async -> FearGreedEntry {
        await withCheckedContinuation { continuation in
            viewModel.getFearGreed { result in
                switch result {
                case .success(let entry):
                    continuation.resume(returning: entry.copyWithPlaceholder())
                case .failure(_):
                    continuation.resume(returning: placeholder(in: context))
                }
            }
        }
    }
    
    func timeline(for configuration: Intent, in context: Context) async -> Timeline<FearGreedEntry> {
        await withCheckedContinuation { continuation in
            viewModel.getFearGreed { result in
                switch result {
                case .success(let entry):
                    let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * (entry.hasPro ? 3 : 15))))
                    continuation.resume(returning: timeline)
                case .failure(let error):
                    print(error)
                    let timeline = Timeline(entries: [FearGreedEntry.empty()], policy: .after(Date().addingTimeInterval(60 * 2)))
                    continuation.resume(returning: timeline)
                }
            }
        }
    }
}

struct FearGreedEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var scheme
    
    let entry: FearGreedProvider.Entry
    
    var body: some View {
        let proGatedModel =
        entry.fearModel 
        
        switch family {
        case .systemSmall:
            SmallFearGreedWidget(fearGreedModel: entry.fearModel)
                .widgetContainerBackground()
            
        case .systemMedium:
            MediumFearGreedWidget(fearGreedModel: proGatedModel, hasBoughtPro: entry.hasPro)
                .widgetContainerBackground()
            
        case .systemLarge:
            LargeFearGreedWidget(fearGreedModel: proGatedModel, hasBoughtPro: entry.hasPro)
                .widgetContainerBackground()
            
        case .accessoryInline:
            InlineFearGreedWidget(fearGreedModel: entry.fearModel)
                .widgetBackground(Color.clear)
            
        case .accessoryCircular:
            CircularFearGreedWidget(fearGreedModel: entry.fearModel)
                .widgetBackground(Color.clear)
            
        case .accessoryRectangular:
            RectangularFearGreedWidget(fearGreedModel: entry.fearModel, hasBoughtPro: entry.hasPro)
                .widgetBackground(Color.clear)
            
        default:
            Text("")
                .widgetBackground(Color.clear)
        }
    }
}


struct FearGreedWidget: Widget {
    
    private let kind = "My_Fear_Greed_Widget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: CryptoWidgetConfigurationIntent.self,
            provider: FearGreedProvider(),
            content: { entry in
                FearGreedEntryView(entry: entry)
            }
        )
        .configurationDisplayName("Fear and Greed widgets")
        .description("Keep track of the Fear and Greed index. All in one widget")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular, .systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

