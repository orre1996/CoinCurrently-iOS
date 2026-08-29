//
//  WidgetContainerBackgroundModifier.swift
//  CryptoWidgetExtension
//

import SwiftUI
import WidgetKit

extension View {
    /// Applies a removable widget background that stays visible in full-color mode
    /// and is omitted in clear/tint rendering modes so content remains visible.
    func widgetContainerBackground(_ color: Color = Color("WidgetBackground")) -> some View {
        modifier(WidgetContainerBackgroundModifier(color: color))
    }

    func widgetBackground(_ backgroundView: some View) -> some View {
        containerBackground(for: .widget) {
            backgroundView
        }
    }
}

private struct WidgetContainerBackgroundModifier: ViewModifier {
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    let color: Color

    func body(content: Content) -> some View {
        content.containerBackground(for: .widget) {
            switch widgetRenderingMode {
            case .fullColor:
                color
            default:
                Color.clear
            }
        }
    }
}
