//
//  NewsProvider.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2022-02-21.
//

import AppIntents
import Foundation
@preconcurrency import WidgetKit
import SwiftUI

struct NewsProvider: AppIntentTimelineProvider {
    typealias Entry = NewsEntry
    typealias Intent = CryptoWidgetConfigurationIntent

    private let viewModel = WidgetViewModelImp()
    
    func placeholder(in context: Context) -> NewsEntry {
        return NewsEntry.empty()
    }
    
    func snapshot(for configuration: Intent, in context: Context) async -> NewsEntry {
        let newsType = await configuration.resolvedNewsType()
        return await withCheckedContinuation { continuation in
            viewModel.getNews(type: newsType, category: configuration.category, itemCount: 3) { result in
                switch result {
                case .success(let entry):
                    continuation.resume(returning: entry.copyWithPlaceholder())
                case .failure(_):
                    continuation.resume(returning: placeholder(in: context))
                }
            }
        }
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<NewsEntry> {
        let newsType = await configuration.resolvedNewsType()
        return await withCheckedContinuation { continuation in
            viewModel.getNews(type: newsType, category: configuration.category, itemCount: 3) { result in
                switch result {
                case .success(let entry):
                    let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * (entry.hasPro ? 3 : 15))))
                    continuation.resume(returning: timeline)
                case .failure(_):
                    let timeline = Timeline(entries: [NewsEntry.empty()], policy: .after(Date().addingTimeInterval(60 * 2)))
                    continuation.resume(returning: timeline)
                }
            }
        }
    }
}

struct NewsWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var scheme
    
    let entry: NewsProvider.Entry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallNewsWidget(
                newsItem: entry.newsModel.first,
                showBuyProOverlay: entry.showBuyProOverlay
            )
            .widgetContainerBackground()
            
        case .systemMedium:
            MediumNewsWidget(entry: entry)
                .widgetContainerBackground()
            
        case .accessoryRectangular:
            RectangularNewsWidget(entry: entry.newsModel.first)
                .widgetBackground(Color.clear)
            
        default:
            Text("")
                .widgetBackground(Color.clear)
        }
    }
}


struct NewsWidget: Widget {
    private let kind = "My_News_Widget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: CryptoWidgetConfigurationIntent.self,
            provider: NewsProvider(),
            content: { entry in
                NewsWidgetEntryView(entry: entry)
            }
        )
        .configurationDisplayName("News widgets")
        .description("Keep track of the latest crypto news. All in one widget")
        .supportedFamilies([.accessoryRectangular, .systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
