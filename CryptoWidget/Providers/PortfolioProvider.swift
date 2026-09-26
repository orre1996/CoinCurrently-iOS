//
//  SingleWidgetProvider.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2020-11-06.
//

import SwiftUI
@preconcurrency import WidgetKit

struct PortfolioProvider: TimelineProvider {
    typealias Entry = PortfolioEntry
    
    private let viewModel = WidgetViewModelImp()
    
    func placeholder(in context: Context) -> PortfolioEntry {
        PortfolioEntry.empty()
    }
    
    func getSnapshot(in context: Context, completion: @escaping (PortfolioEntry) -> Void) {
        viewModel.getPortfolio { result in
            switch result {
            case .success(let entry):
                completion(entry.copyWithPlaceholder())
            case .failure:
                completion(self.placeholder(in: context))
            }
        }
    }
    
    func getTimeline(in _: Context, completion: @escaping (Timeline<PortfolioEntry>) -> Void) {
        viewModel.getPortfolio { result in
            switch result {
            case .success(let entry):
                completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(WidgetRefreshInterval.loaded))))
            case .failure:
                completion(Timeline(entries: [PortfolioEntry.empty()], policy: .after(Date().addingTimeInterval(WidgetRefreshInterval.retry))))
            }
        }
    }
}

struct PortfolioWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var scheme
    
    let entry: PortfolioProvider.Entry
    
    var body: some View {
        if entry.portfolioCoins.isEmpty {
            PortfolioWidgetEmptyView()
                .widgetContainerBackground()
        } else {
            switch family {
            case .systemSmall:
                SmallPortfolioWidget(entry: entry)
                    .widgetContainerBackground()
                
            case .systemMedium:
                MediumPortfolioWidget(entry: entry)
                    .widgetContainerBackground()
                
            case .systemLarge:
                LargePortfolioWidget(entry: entry)
                    .widgetContainerBackground()
                
            case .accessoryInline:
                InlinePortfolioWidget(entry: entry)
                    .widgetBackground(Color.clear)
                
            case .accessoryRectangular:
                RectangularPortfolioWidget(entry: entry)
                    .widgetContainerBackground(Color.clear)
                
            default:
                Text("")
                    .widgetBackground(Color.clear)
            }
        }
    }
}


struct PortfolioWidget: Widget {
    
    private let kind = "My_Portfolio_Widget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PortfolioProvider()) { entry in
            PortfolioWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Portfolio widgets")
        .description("Keep track of your crypto portfolio. All in one widget")
        .supportedFamilies([.accessoryInline, .accessoryRectangular, .systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
