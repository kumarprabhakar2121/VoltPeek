import SwiftUI

/// Token set that drives how a theme renders.
struct ThemeProfile: Sendable {
    let cornerRadius: CGFloat
    let baseWidth: CGFloat
    let sectionSpacing: CGFloat

    static func profile(for theme: PopoverTheme) -> ThemeProfile {
        switch theme {
        case .compact:
            return ThemeProfile(
                cornerRadius: 0,
                baseWidth: 288,
                sectionSpacing: 7
            )
        case .material:
            return ThemeProfile(
                cornerRadius: 14,
                baseWidth: 312,
                sectionSpacing: 12
            )
        case .liquidGlass:
            return ThemeProfile(
                cornerRadius: 18,
                baseWidth: 336,
                sectionSpacing: 14
            )
        }
    }
}

/// Vision accessibility flags injected into the popover environment.
struct ThemeAccessibility: Equatable, Sendable {
    var increaseContrast: Bool
    var boldText: Bool
    var reduceTransparency: Bool
    var differentiateWithoutColor: Bool

    static let `default` = ThemeAccessibility(
        increaseContrast: false,
        boldText: false,
        reduceTransparency: false,
        differentiateWithoutColor: false
    )

    init(
        increaseContrast: Bool,
        boldText: Bool,
        reduceTransparency: Bool,
        differentiateWithoutColor: Bool
    ) {
        self.increaseContrast = increaseContrast
        self.boldText = boldText
        self.reduceTransparency = reduceTransparency
        self.differentiateWithoutColor = differentiateWithoutColor
    }

    init(_ prefs: AccessibilityPreferences, systemDifferentiateWithoutColor: Bool = false) {
        increaseContrast = prefs.increaseContrast
        boldText = prefs.boldText
        reduceTransparency = prefs.reduceTransparency
        differentiateWithoutColor = prefs.differentiateWithoutColor || systemDifferentiateWithoutColor
    }

    var metricWeight: Font.Weight { boldText ? .heavy : .semibold }
    var bodyWeight: Font.Weight { boldText ? .bold : .regular }
    var secondaryOpacity: Double { increaseContrast ? 1.0 : 0.7 }
    var borderOpacity: Double { increaseContrast ? 0.55 : 0.22 }
    var borderWidth: CGFloat { increaseContrast ? 2 : 1 }
}

/// Scaled type sizes derived from font preference + UI scale.
struct ThemeTypography: Equatable {
    let fontMultiplier: CGFloat
    let scale: CGFloat
    let a11y: ThemeAccessibility

    private var factor: CGFloat {
        let contrastBump: CGFloat = a11y.increaseContrast ? 1.1 : 1.0
        return fontMultiplier * scale * contrastBump
    }

    var title: Font { .system(size: 22 * factor, weight: a11y.boldText ? .heavy : .semibold, design: .default) }
    var metric: Font { .system(size: 15 * factor, weight: a11y.metricWeight, design: .default) }
    var metricEmphasized: Font { .system(size: 17 * factor, weight: a11y.metricWeight, design: .default) }
    var body: Font { .system(size: 13 * factor, weight: a11y.bodyWeight) }
    var caption: Font { .system(size: 11 * factor, weight: a11y.boldText ? .bold : .medium) }
    var caption2: Font { .system(size: 10 * factor, weight: a11y.boldText ? .semibold : .regular) }
    var heroMetric: Font { .system(size: 20 * factor, weight: a11y.boldText ? .heavy : .semibold, design: .default) }
}

// MARK: - Environment

private struct ThemeScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

private struct ThemeProfileKey: EnvironmentKey {
    static let defaultValue = ThemeProfile.profile(for: .compact)
}

private struct ThemeAccessibilityKey: EnvironmentKey {
    static let defaultValue = ThemeAccessibility.default
}

private struct ThemeTypographyKey: EnvironmentKey {
    static let defaultValue = ThemeTypography(
        fontMultiplier: 1,
        scale: 1,
        a11y: .default
    )
}

extension EnvironmentValues {
    var themeScale: CGFloat {
        get { self[ThemeScaleKey.self] }
        set { self[ThemeScaleKey.self] = newValue }
    }

    var themeProfile: ThemeProfile {
        get { self[ThemeProfileKey.self] }
        set { self[ThemeProfileKey.self] = newValue }
    }

    var themeAccessibility: ThemeAccessibility {
        get { self[ThemeAccessibilityKey.self] }
        set { self[ThemeAccessibilityKey.self] = newValue }
    }

    var themeTypography: ThemeTypography {
        get { self[ThemeTypographyKey.self] }
        set { self[ThemeTypographyKey.self] = newValue }
    }
}

extension View {
    /// Applies persisted font + UI scale + theme profile + accessibility into the environment.
    func themeEnvironment(
        theme: PopoverTheme,
        fontSize: FontSizePreference,
        uiScale: UIScalePreference,
        accessibility: AccessibilityPreferences,
        systemDifferentiateWithoutColor: Bool = false
    ) -> some View {
        let a11y = ThemeAccessibility(
            accessibility,
            systemDifferentiateWithoutColor: systemDifferentiateWithoutColor
        )
        let typography = ThemeTypography(
            fontMultiplier: fontSize.multiplier * (a11y.increaseContrast ? 1.1 : 1.0),
            scale: uiScale.multiplier,
            a11y: a11y
        )
        return environment(\.themeProfile, ThemeProfile.profile(for: theme))
            .environment(\.themeScale, uiScale.multiplier)
            .environment(\.themeAccessibility, a11y)
            .environment(\.themeTypography, typography)
    }
}
