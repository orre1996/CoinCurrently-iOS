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
    typealias Intent = FearGreedWidgetConfigurationIntent
    
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
                    let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(WidgetRefreshInterval.loaded)))
                    continuation.resume(returning: timeline)
                case .failure(let error):
                    print(error)
                    let timeline = Timeline(entries: [FearGreedEntry.empty()], policy: .after(Date().addingTimeInterval(WidgetRefreshInterval.retry)))
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
        switch family {
        case .systemSmall:
            SmallFearGreedWidget(fearGreedModel: entry.fearModel)
                .widgetContainerBackground()
            
        case .accessoryInline:
            InlineFearGreedWidget(fearGreedModel: entry.fearModel)
                .widgetBackground(Color.clear)
            
        case .accessoryCircular:
            CircularFearGreedWidget(fearGreedModel: entry.fearModel)
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
            intent: FearGreedWidgetConfigurationIntent.self,
            provider: FearGreedProvider(),
            content: { entry in
                FearGreedEntryView(entry: entry)
            }
        )
        .configurationDisplayName("Fear and Greed widgets")
        .description("Keep track of the Fear and Greed index. All in one widget")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .systemSmall])
        .contentMarginsDisabled()
    }
}

