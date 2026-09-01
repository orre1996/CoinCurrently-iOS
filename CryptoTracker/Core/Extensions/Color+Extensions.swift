//
//  Color+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 3/29/25.
//

import SwiftUI
import UIKit

enum AppColorScheme: String, CaseIterable {
    case light = "Light Mode"
    case dark = "Dark Mode"
    case system = "System"

    func resolvedColorScheme(for scheme: ColorScheme) -> ColorScheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return scheme
        }
    }
    
    var preferredScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

extension Color {
    private static func theme(lightHex: String, darkHex: String, assetName: String) -> Color {
        #if os(watchOS) || os(iOS)
        Color(assetName)
        #else
        Color(
            UIColor { traitCollection in
                UIColor(
                    Color(
                        hex: traitCollection.userInterfaceStyle == .dark ? darkHex : lightHex
                    )
                )
            }
        )
        #endif
    }

    /// Color-blind-friendly palette; uses asset catalog on iOS/watchOS (same as `theme`).
    private static func accessibleTheme(lightHex: String, darkHex: String, assetName: String) -> Color {
        theme(lightHex: lightHex, darkHex: darkHex, assetName: assetName)
    }

    #if IS_APP || IS_WATCH
    private static var usesAccessibleSemanticColors: Bool {
        SettingsManager.shared.isColorBlindnessFilterEnabled()
    }
    #endif

    static let surface = theme(lightHex: "#E5E2E1", darkHex: "#111111", assetName: "surface")
    static let onSurfaceContainer = theme(lightHex: "#1C1B1B", darkHex: "#F6FEFF", assetName: "onSurfaceContainer")
    static let surfaceContainer = theme(lightHex: "#EBE8E7", darkHex: "#262625", assetName: "surfaceContainer")
    static let surfaceContainerHigh = theme(lightHex: "#EDEAE9", darkHex: "#313030", assetName: "surfaceContainerHigh")
    static let surfaceContainerHighest = theme(lightHex: "#FCF8F8", darkHex: "#484646", assetName: "surfaceContainerHighest")
    static let surfaceContainerLow = theme(lightHex: "#DEDAD9", darkHex: "#1C1B1B", assetName: "surfaceContainerLow")
    static let surfaceContainerLowest = theme(lightHex: "#C9C6C5", darkHex: "#111111", assetName: "surfaceContainerLowest")
    static let onPrimary = theme(lightHex: "#FFFFFF", darkHex: "#1B0E00", assetName: "onPrimary")
    static let primary = theme(lightHex: "#8F5F00", darkHex: "#EA9A00", assetName: "primary")
    static let primary20 = theme(lightHex: "#452B00", darkHex: "#452B00", assetName: "primary20")
    static let primary50 = theme(lightHex: "#A46B00", darkHex: "#A46B00", assetName: "primary50")
    static let primary90 = theme(lightHex: "#FFEEDD", darkHex: "#FFDDB5", assetName: "primary90")
    static let secondary15 = theme(lightHex: "#31230E", darkHex: "#31230E", assetName: "secondary15")
    static let blue50 = theme(lightHex: "#006AC2", darkHex: "#006AC2", assetName: "blue50")
    static let primaryContainer = theme(lightHex: "#FFEEDD", darkHex: "#372100", assetName: "primaryContainer")
    static let onSurfaceDim = theme(lightHex: "#484646", darkHex: "#C9C6C5", assetName: "onSurfaceDim")
    static let onSurfaceContainerDim = theme(lightHex: "#6C6A6A", darkHex: "#ADAAAA", assetName: "onSurfaceContainerDim")
    static let onSurfaceDimmer = theme(lightHex: "#6C6A6A", darkHex: "#929090", assetName: "onSurfaceDimmer")
    static let onSurfaceDimmest = theme(lightHex: "#929090", darkHex: "#605E5E", assetName: "onSurfaceDimmest")
    static let inverseOnSurface = theme(lightHex: "#E5E2E1", darkHex: "#1C1B1B", assetName: "inverseOnSurface")
    static let onSurface = theme(lightHex: "#1C1B1B", darkHex: "#FCF8F8", assetName: "onSurface")
    static let outline = theme(lightHex: "#929090", darkHex: "#797776", assetName: "outline")
    static let outlineVariant = theme(lightHex: "#C9C6C5", darkHex: "#313030", assetName: "outlineVariant")
    static let inverseOnContainer = theme(lightHex: "#E5E2E1", darkHex: "#1C1B1B", assetName: "inverseOnContainer")
    static let inverseSurface = theme(lightHex: "#1C1B1B", darkHex: "#E5E2E1", assetName: "inverseSurface")
    // Standard palette (green = up, red = down)
    private static let standardTrendUp = theme(lightHex: "#007F52", darkHex: "#42E099", assetName: "trendUp")
    private static let standardTrendDown = theme(lightHex: "#B3272A", darkHex: "#F95A56", assetName: "trendDown")
    private static let standardExtremeFear = theme(lightHex: "#C43435", darkHex: "#F95A56", assetName: "extremeFear")
    private static let standardFear = theme(lightHex: "#C96800", darkHex: "#FB9145", assetName: "fear")
    private static let standardNeutral = theme(lightHex: "#9A8200", darkHex: "#FFDF2E", assetName: "neutral")
    private static let standardGreed = theme(lightHex: "#4A8C00", darkHex: "#A8DF5F", assetName: "greed")
    private static let standardExtremeGreed = theme(lightHex: "#007F52", darkHex: "#42E099", assetName: "extremeGreed")

    // Okabe–Ito–inspired palette: blue/orange for up/down; distinct hues for Fear & Greed scale
    private static let accessibleTrendUp = accessibleTheme(lightHex: "#0072B2", darkHex: "#56B4E9", assetName: "accessibleTrendUp")
    private static let accessibleTrendDown = accessibleTheme(lightHex: "#D55E00", darkHex: "#E69F00", assetName: "accessibleTrendDown")
    private static let accessibleExtremeFear = accessibleTheme(lightHex: "#882255", darkHex: "#C77CFF", assetName: "accessibleExtremeFear")
    private static let accessibleFear = accessibleTheme(lightHex: "#D55E00", darkHex: "#FF9F4A", assetName: "accessibleFear")
    private static let accessibleNeutral = accessibleTheme(lightHex: "#757575", darkHex: "#B8B8B8", assetName: "accessibleNeutral")
    private static let accessibleGreed = accessibleTheme(lightHex: "#009E99", darkHex: "#4ECDC4", assetName: "accessibleGreed")
    private static let accessibleExtremeGreed = accessibleTheme(lightHex: "#0072B2", darkHex: "#56B4E9", assetName: "accessibleTrendUp")

    static var trendUp: Color {
        #if IS_APP || IS_WATCH
        usesAccessibleSemanticColors ? accessibleTrendUp : standardTrendUp
        #else
        standardTrendUp
        #endif
    }

    static var trendDown: Color {
        #if IS_APP || IS_WATCH
        usesAccessibleSemanticColors ? accessibleTrendDown : standardTrendDown
        #else
        standardTrendDown
        #endif
    }

    static var extremeFear: Color {
        #if IS_APP || IS_WATCH
        usesAccessibleSemanticColors ? accessibleExtremeFear : standardExtremeFear
        #else
        standardExtremeFear
        #endif
    }

    static var fear: Color {
        #if IS_APP || IS_WATCH
        usesAccessibleSemanticColors ? accessibleFear : standardFear
        #else
        standardFear
        #endif
    }

    static var neutral: Color {
        #if IS_APP || IS_WATCH
        usesAccessibleSemanticColors ? accessibleNeutral : standardNeutral
        #else
        standardNeutral
        #endif
    }

    static var greed: Color {
        #if IS_APP || IS_WATCH
        usesAccessibleSemanticColors ? accessibleGreed : standardGreed
        #else
        standardGreed
        #endif
    }

    static var extremeGreed: Color {
        #if IS_APP || IS_WATCH
        usesAccessibleSemanticColors ? accessibleExtremeGreed : standardExtremeGreed
        #else
        standardExtremeGreed
        #endif
    }

    static let overlayBackground = Color("overlayBackground")
    
    static let shimmeringBackground = Color("shimmeringBackground")
    
    var uiColor: UIColor {
        UIColor(self)
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func hexStringFromColor() -> String {
        let components = self.cgColor?.components
        
        if (components?.count ?? 0) >= 3 {
            let r: CGFloat = components?[0] ?? 0.0
            let g: CGFloat = components?[1] ?? 0.0
            let b: CGFloat = components?[2] ?? 0.0
            
            let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
            return hexString
        } else {
            return "C9C6C5"
        }
    }
}
