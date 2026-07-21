import AppKit
import SwiftUI

/// Shared adaptive colors for distinct window, navigation, and content layers.
enum AppPalette {
    static let canvas = adaptive(
        light: NSColor(red: 0.945, green: 0.955, blue: 0.975, alpha: 1),
        dark: NSColor(red: 0.070, green: 0.080, blue: 0.100, alpha: 1)
    )

    static let sidebar = adaptive(
        light: NSColor(red: 0.900, green: 0.920, blue: 0.955, alpha: 1),
        dark: NSColor(red: 0.095, green: 0.110, blue: 0.140, alpha: 1)
    )

    static let toolbar = adaptive(
        light: NSColor(red: 0.975, green: 0.980, blue: 0.990, alpha: 1),
        dark: NSColor(red: 0.090, green: 0.102, blue: 0.125, alpha: 1)
    )

    static let surface = adaptive(
        light: .white,
        dark: NSColor(red: 0.115, green: 0.130, blue: 0.160, alpha: 1)
    )

    static let raisedSurface = adaptive(
        light: NSColor(red: 0.975, green: 0.980, blue: 0.990, alpha: 1),
        dark: NSColor(red: 0.145, green: 0.160, blue: 0.195, alpha: 1)
    )

    static let border = adaptive(
        light: NSColor.black.withAlphaComponent(0.12),
        dark: NSColor.white.withAlphaComponent(0.13)
    )

    private static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
}
