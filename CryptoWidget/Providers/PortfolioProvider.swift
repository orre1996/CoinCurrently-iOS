//
//  SingleWidgetProvider.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2020-11-06.
//

import AppIntents
import SwiftUI
@preconcurrency import WidgetKit

struct PortfolioProvider: AppIntentTimelineProvider {
    typealias Entry = PortfolioEntry
    typealias Intent = PortfolioWidgetConfigurationIntent
    
    private let viewModel = WidgetViewModelImp()
    
    func placeholder(in context: Context) -> PortfolioEntry {
        PortfolioEntry.empty()
    }
    
    func snapshot(for configuration: Intent, in context: Context) async -> PortfolioEntry {
        await withCheckedContinuation { continuation in
            viewModel.getPortfolio { result in
                switch result {
                case .success(let entry):
                    continuation.resume(returning: entry.copyWithPlaceholder())
                case .failure(_):
                    continuation.resume(returning: placeholder(in: context))
                }
            }
        }
    }
    
    func timeline(for configuration: Intent, in context: Context) async -> Timeline<PortfolioEntry> {
        await withCheckedContinuation { continuation in
            viewModel.getPortfolio { result in
                switch result {
                case .success(let entry):
                    let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * (entry.hasPro ? 3 : 15))))
                    continuation.resume(returning: timeline)
                case .failure(_):
                    let timeline = Timeline(entries: [PortfolioEntry.empty()], policy: .after(Date().addingTimeInterval(60 * 2)))
                    continuation.resume(returning: timeline)
                }
            }
        }
    }
}

struct PortfolioWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var scheme
    
    let entry: PortfolioProvider.Entry
    
    var body: some View {
        /* if GlobalFunctions.shared.getHidePortfolioWidgets() {
         let text = family == .accessoryInline ? "Portfolio widgets disabled" : family == .accessoryRectangular ? "Portfolio widgets are disabled" : "Portfolio widgets are disabled.\n\nEnable in app settings."
         
         ZStack {
         AccessoryWidgetBackground()
         .cornerRadius(8)
         
         Text(text)
         .if(family != .accessoryInline && family != .accessoryRectangular) { view in
         view.foregroundColor(Color.onSurface(for: scheme))
         .font(.regular16)
         }
         .if(family == .accessoryRectangular) { view in
         view.font(.system(size: 11, weight: .medium))
         }
         .multilineTextAlignment(.center)
         .frame(maxWidth: .infinity, maxHeight: .infinity)
         .padding(4)
         }
         .containerBackground(Color.widgetBackground(for: scheme), for: .widget)
         
         } else {*/
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
        AppIntentConfiguration(
            kind: kind,
            intent: PortfolioWidgetConfigurationIntent.self,
            provider: PortfolioProvider(),
            content: { entry in
                PortfolioWidgetEntryView(entry: entry)
            })
        .configurationDisplayName("Portfolio widgets")
        .description("Keep track of your crypto portfolio. All in one widget")
        .supportedFamilies([.accessoryInline, .accessoryRectangular, .systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
