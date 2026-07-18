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
    case text
    case battery
    case batteryPercent
    case bolt
    case boltWatts
    case batteryBolt

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text: return "Text"
        case .battery: return "Battery"
        case .batteryPercent: return "Battery + %"
        case .bolt: return "Power bolt"
        case .boltWatts: return "Bolt + Watts"
        case .batteryBolt: return "Battery (auto bolt)"
        }
    }

    var subtitle: String {
        switch self {
        case .text: return "Emoji / text watts and percent"
        case .battery: return "System-like battery icon by fill"
        case .batteryPercent: return "Battery icon with percentage"
        case .bolt: return "Lightning bolt power icon"
        case .boltWatts: return "Bolt with live signed watts"
        case .batteryBolt: return "Bolt when charging, else battery"
        }
    }
}

/// Relative typography size for the popover.
enum FontSizePreference: String, CaseIterable, Identifiable, Sendable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

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

    var title: String {
        switch self {
        case .compact85: return "85%"
        case .standard: return "100%"
        case .large115: return "115%"
        case .xlarge130: return "130%"
        }
    }

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

/// User-configurable preferences persisted via UserDefaults.
struct AppSettings: Equatable, Sendable {
    var refreshIntervalSeconds: Double
    var showWattsInMenuBar: Bool
    var showPercentageInMenuBar: Bool
    var launchAtLogin: Bool
    var popoverTheme: PopoverTheme
    var fontSize: FontSizePreference
    var uiScale: UIScalePreference
    var accessibility: AccessibilityPreferences
    var menuBarStyle: MenuBarStyle

    static let `default` = AppSettings(
        refreshIntervalSeconds: 3,
        showWattsInMenuBar: true,
        showPercentageInMenuBar: true,
        launchAtLogin: false,
        popoverTheme: .compact,
        fontSize: .medium,
        uiScale: .standard,
        accessibility: .default,
        menuBarStyle: .text
    )

    /// Allowed discrete refresh intervals shown in Settings.
    static let refreshIntervalOptions: [Double] = [0.5, 1, 2, 3, 5, 10]

    static func clampedInterval(_ value: Double) -> Double {
        let clamped = min(max(value, 0.5), 10)
        // Snap to nearest allowed option so polling stays on known steps.
        return refreshIntervalOptions.min(by: { abs($0 - clamped) < abs($1 - clamped) }) ?? 3
    }
}
