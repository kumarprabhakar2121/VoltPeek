import Foundation
import SwiftUI

/// Visual style for the menu bar popover.
enum PopoverTheme: String, CaseIterable, Identifiable, Sendable {
    case compact
    case material
    case liquidGlass

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: return "List"
        case .material: return "Cards"
        case .liquidGlass: return "Glass"
        }
    }

    var subtitle: String {
        switch self {
        case .compact: return "Dense list — fast to scan"
        case .material: return "Elevated cards — clear groups"
        case .liquidGlass: return "Frosted panels — calm glance"
        }
    }
}

/// How the menu bar extra is rendered.
enum MenuBarStyle: String, CaseIterable, Identifiable, Sendable {
    case battery
    case watts
    case both
    case hidden

    var id: String { rawValue }

    var title: String {
        switch self {
        case .battery: return "Battery"
        case .watts: return "Watts"
        case .both: return "Both"
        case .hidden: return "Hidden"
        }
    }

    var subtitle: String {
        switch self {
        case .battery: return "Percentage and system battery icon"
        case .watts: return "Live charging power"
        case .both: return "Watts plus battery"
        case .hidden: return "Do not show a menu bar item"
        }
    }

    /// Maps current and legacy UserDefaults raw values to the slim style set.
    static func migrating(fromRaw raw: String?) -> MenuBarStyle {
        guard let raw else { return .battery }
        if let style = MenuBarStyle(rawValue: raw) {
            return style
        }
        switch raw {
        case "batteryPercent", "batteryBolt", "batteryIcon", "iconAndPercent":
            return .battery
        case "boltWatts", "bolt":
            return .watts
        case "text":
            return .both
        default:
            return .battery
        }
    }
}

/// Relative typography size for the popover.
enum FontSizePreference: String, CaseIterable, Identifiable, Sendable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var multiplier: CGFloat {
        switch self {
        case .small: return 0.90
        case .medium: return 1.0
        case .large: return 1.15
        }
    }
}

/// Overall UI scale for spacing, rings, tiles, and popover width.
enum UIScalePreference: String, CaseIterable, Identifiable, Sendable {
    case compact85
    case standard
    case large115
    case xlarge130

    var id: String { rawValue }

    var multiplier: CGFloat {
        switch self {
        case .compact85: return 0.85
        case .standard: return 1.0
        case .large115: return 1.15
        case .xlarge130: return 1.30
        }
    }
}

/// Single Display Size control that maps to font + UI scale pairs.
enum DisplaySizePreference: String, CaseIterable, Identifiable, Sendable {
    case compact
    case standard
    case large
    case extraLarge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: return "Compact"
        case .standard: return "Default"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }

    var fontSize: FontSizePreference {
        switch self {
        case .compact: return .small
        case .standard: return .medium
        case .large, .extraLarge: return .large
        }
    }

    var uiScale: UIScalePreference {
        switch self {
        case .compact: return .compact85
        case .standard: return .standard
        case .large: return .large115
        case .extraLarge: return .xlarge130
        }
    }

    static func matching(fontSize: FontSizePreference, uiScale: UIScalePreference) -> DisplaySizePreference {
        let match = DisplaySizePreference.allCases.first {
            $0.fontSize == fontSize && $0.uiScale == uiScale
        }
        if let match { return match }

        switch uiScale {
        case .compact85: return .compact
        case .standard: return .standard
        case .large115: return .large
        case .xlarge130: return .extraLarge
        }
    }
}

/// Vision-related accessibility preferences (in-app).
struct AccessibilityPreferences: Equatable, Sendable {
    var increaseContrast: Bool
    var boldText: Bool
    var reduceTransparency: Bool
    var differentiateWithoutColor: Bool

    static let `default` = AccessibilityPreferences(
        increaseContrast: false,
        boldText: false,
        reduceTransparency: false,
        differentiateWithoutColor: false
    )

    var fingerprint: String {
        "\(increaseContrast)-\(boldText)-\(reduceTransparency)-\(differentiateWithoutColor)"
    }
}

/// How the menu bar battery glyph is colored.
enum MenuBarBatteryAppearance: String, CaseIterable, Identifiable, Sendable {
    case colored
    case monochrome

    var id: String { rawValue }

    var title: String {
        switch self {
        case .colored: return "Colored"
        case .monochrome: return "Black & White"
        }
    }
}

/// User-configurable preferences persisted via UserDefaults.
struct AppSettings: Equatable, Sendable {
    var refreshIntervalSeconds: Double
    var launchAtLogin: Bool
    var popoverTheme: PopoverTheme
    var fontSize: FontSizePreference
    var uiScale: UIScalePreference
    var accessibility: AccessibilityPreferences
    var menuBarStyle: MenuBarStyle
    var menuBarBatteryAppearance: MenuBarBatteryAppearance
    var appScalePercent: Int

    static let `default` = AppSettings(
        refreshIntervalSeconds: 3,
        launchAtLogin: false,
        popoverTheme: .compact,
        fontSize: .medium,
        uiScale: .standard,
        accessibility: .default,
        menuBarStyle: .battery,
        menuBarBatteryAppearance: .colored,
        appScalePercent: 100
    )

    /// Allowed discrete refresh intervals shown in Settings.
    static let refreshIntervalOptions: [Double] = [0.5, 1, 2, 3, 5, 10]
    static let appScaleOptions: [Int] = Array(stride(from: 100, through: 300, by: 25))

    static func clampedInterval(_ value: Double) -> Double {
        let clamped = min(max(value, 0.5), 10)
        // Snap to nearest allowed option so polling stays on known steps.
        return refreshIntervalOptions.min(by: { abs($0 - clamped) < abs($1 - clamped) }) ?? 3
    }

    static func clampedAppScale(_ value: Int) -> Int {
        appScaleOptions.min(by: { abs($0 - value) < abs($1 - value) }) ?? 100
    }
}
