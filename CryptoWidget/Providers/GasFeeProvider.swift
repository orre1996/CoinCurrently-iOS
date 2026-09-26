//
//  GasFeeProvider.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2024-03-20.
//

import AppIntents
import Foundation
@preconcurrency import WidgetKit
import SwiftUI

struct GasFeeProvider: AppIntentTimelineProvider {
    typealias Entry = GasFeeEntry
    typealias Intent = GasFeeWidgetConfigurationIntent
    
    private let viewModel = WidgetViewModelImp()
    
    func placeholder(in context: Context) -> GasFeeEntry {
        GasFeeEntry.empty()
    }
    
    func snapshot(for configuration: Intent, in context: Context) async -> GasFeeEntry {
        await withCheckedContinuation { continuation in
            viewModel.getGasFees { result in
                switch result {
                case .success(let entry):
                    continuation.resume(returning: entry)
                case .failure(_):
                    continuation.resume(returning: placeholder(in: context))
                }
            }
        }
    }
    
    func timeline(for configuration: Intent, in context: Context) async -> Timeline<GasFeeEntry> {
        await withCheckedContinuation { continuation in
            viewModel.getGasFees { result in
                switch result {
                case .success(let entry):
                    let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(WidgetRefreshInterval.loaded)))
                    continuation.resume(returning: timeline)
                case .failure(let error):
                    print(error)
                    let timeline = Timeline(entries: [GasFeeEntry.empty()], policy: .after(Date().addingTimeInterval(WidgetRefreshInterval.retry)))
                    continuation.resume(returning: timeline)
                }
            }
        }
    }
}

struct GasFeesWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var scheme

    let entry: GasFeeProvider.Entry

    var body: some View {

        switch family {

        case .systemSmall:
            SmallGasFeesWidget(gasFees: entry.gasFeesModel)
                .widgetContainerBackground()
            
        case .accessoryRectangular:
            RectangularGasFeesWidget(gasFees: entry.gasFeesModel)
                .widgetBackground(Color.clear)

        default:
            Text("")
                .widgetBackground(Color.clear)
        }
    }
}


struct GasFeesWidget: Widget {
    
    private let kind = "My_Gas_Fees_Widget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: GasFeeWidgetConfigurationIntent.self,
            provider: GasFeeProvider(),
            content: { entry in
                GasFeesWidgetEntryView(entry: entry)
            }
        )
        .configurationDisplayName("Ethereum gas fees widgets")
        .description("Keep track of the latest Ethereum gas fees. All in one widget")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

