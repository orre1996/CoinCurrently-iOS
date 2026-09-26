import SwiftUI
import UIKit

// MARK: - SwiftUI Colors (Environment-driven)

extension Color {

    // MARK: Core

    static func surface(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(hex: "#111111")
        case .light:
            Color(hex: "#E5E2E1")
        @unknown default:
            Color(hex: "#111111")
        }
    }

    static func surfaceContainerHigh(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(hex: "#313030")
        case .light:
            Color(hex: "#EDEAE9")
        @unknown default:
            Color(hex: "#313030")
        }
    }

    static func surfaceContainerHighest(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(hex: "#484646")
        case .light:
            Color(hex: "#FCF8F8")
        @unknown default:
            Color(hex: "#484646")
        }
    }

    static func onSurface(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(hex: "#FCF8F8")
        case .light:
            Color(hex: "#1C1B1B")
        @unknown default:
            Color(hex: "#FCF8F8")
        }
    }
    
    static func onSurfaceDim(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(hex: "#C9C6C5")
        case .light:
            Color(hex: "#484646")
        @unknown default:
            Color(hex: "#C9C6C5")
        }
    }
    
    static func onSurfaceDimmer(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(hex: "#929090")
        case .light:
            Color(hex: "#6C6A6A")
        @unknown default:
            Color(hex: "#929090")
        }
    }
    
    static func onSurfaceDimmest(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(hex: "#605E5E")
        case .light:
            Color(hex: "#929090")
        @unknown default:
            Color(hex: "#605E5E")
        }
    }
    
    static func inverseOnSurface(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(hex: "#1C1B1B")
        case .light:
            Color(hex: "#E5E2E1")
        @unknown default:
            Color(hex: "#1C1B1B")
        }
    }

    static func primary(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(hex: "#EA9A00")
        case .light:
            Color(hex: "#8F5F00")
        @unknown default:
            Color(hex: "#EA9A00")
        }
    }

    static func onPrimary(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(hex: "#1B0E00")
        case .light:
            Color(hex: "#FFFFFF")
        @unknown default:
            Color(hex: "#1B0E00")
        }
    }
    
    private static var usesAccessibleSemanticColors: Bool {
        SettingsManager.shared.isColorBlindnessFilterEnabled()
    }

    static func trendUp(for scheme: ColorScheme) -> Color {
        if usesAccessibleSemanticColors {
            switch scheme {
            case .dark: Color(hex: "#56B4E9")
            case .light: Color(hex: "#0072B2")
            @unknown default: Color(hex: "#56B4E9")
            }
        } else {
            switch scheme {
            case .dark: Color(hex: "#42E099")
            case .light: Color(hex: "#007F52")
            @unknown default: Color(hex: "#42E099")
            }
        }
    }
    
    static func trendDown(for scheme: ColorScheme) -> Color {
        if usesAccessibleSemanticColors {
            switch scheme {
            case .dark: Color(hex: "#E69F00")
            case .light: Color(hex: "#D55E00")
            @unknown default: Color(hex: "#E69F00")
            }
        } else {
            switch scheme {
            case .dark: Color(hex: "#F95A56")
            case .light: Color(hex: "#B3272A")
            @unknown default: Color(hex: "#F95A56")
            }
        }
    }
    
    static func extremeFear(for scheme: ColorScheme) -> Color {
        if usesAccessibleSemanticColors {
            switch scheme {
            case .dark: Color(hex: "#C77CFF")
            case .light: Color(hex: "#882255")
            @unknown default: Color(hex: "#C77CFF")
            }
        } else {
            switch scheme {
            case .dark: Color(hex: "#F95A56")
            case .light: Color(hex: "#C43435")
            @unknown default: Color(hex: "#F95A56")
            }
        }
    }
    
    static func fear(for scheme: ColorScheme) -> Color {
        if usesAccessibleSemanticColors {
            switch scheme {
            case .dark: Color(hex: "#FF9F4A")
            case .light: Color(hex: "#D55E00")
            @unknown default: Color(hex: "#FF9F4A")
            }
        } else {
            switch scheme {
            case .dark: Color(hex: "#FB9145")
            case .light: Color(hex: "#C96800")
            @unknown default: Color(hex: "#FB9145")
            }
        }
    }
    
    static func neutral(for scheme: ColorScheme) -> Color {
        if usesAccessibleSemanticColors {
            switch scheme {
            case .dark: Color(hex: "#B8B8B8")
            case .light: Color(hex: "#757575")
            @unknown default: Color(hex: "#B8B8B8")
            }
        } else {
            switch scheme {
            case .dark: Color(hex: "#FFDF2E")
            case .light: Color(hex: "#9A8200")
            @unknown default: Color(hex: "#FFDF2E")
            }
        }
    }
    
    static func greed(for scheme: ColorScheme) -> Color {
        if usesAccessibleSemanticColors {
            switch scheme {
            case .dark: Color(hex: "#4ECDC4")
            case .light: Color(hex: "#009E99")
            @unknown default: Color(hex: "#4ECDC4")
            }
        } else {
            switch scheme {
            case .dark: Color(hex: "#A8DF5F")
            case .light: Color(hex: "#4A8C00")
            @unknown default: Color(hex: "#A8DF5F")
            }
        }
    }
    
    static func extremeGreed(for scheme: ColorScheme) -> Color {
        trendUp(for: scheme)
    }
    
    static func shimmeringBackground(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(hex: "#E6E9FF")
        case .light:
            Color(hex: "#3A3A43")
        @unknown default:
            Color(hex: "#E6E9FF")
        }
    }

    // MARK: Separators / Outlines
    
    static func outline(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(hex: "#797776")
        case .light:
            Color(hex: "#929090")
        @unknown default:
            Color(hex: "#797776")
        }
    }

    static func outlineVariant(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(hex: "#313030")
        case .light:
            Color(hex: "#C9C6C5")
        @unknown default:
            Color(hex: "#313030")
        }
    }
}

// MARK: - Helpers

extension Color {
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
