//
//  AppShortcutProvider.swift
//  CryptoWidgetExtension
//

import SwiftUI
import WidgetKit

struct AppShortcutEntry: TimelineEntry {
    let date = Date()
}

struct AppShortcutProvider: TimelineProvider {
    func placeholder(in context: Context) -> AppShortcutEntry {
        AppShortcutEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (AppShortcutEntry) -> Void) {
        completion(AppShortcutEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AppShortcutEntry>) -> Void) {
        completion(Timeline(entries: [AppShortcutEntry()], policy: .never))
    }
}

struct AppShortcutWidget: Widget {
    private let kind = "CoinCurrently_App_Shortcut_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AppShortcutProvider()) { _ in
            CircularAppShortcutWidget()
        }
        .configurationDisplayName("Shortcut")
        .description("Open CoinCurrently from the Lock Screen")
        .supportedFamilies([.accessoryCircular])
        .contentMarginsDisabled()
    }
}
