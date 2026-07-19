import Foundation
import ServiceManagement

/// Persists user preferences and manages Launch at Login via `SMAppService`.
@MainActor
@Observable
final class SettingsManager {
    private enum Keys {
        static let refreshInterval = "refreshIntervalSeconds"
        static let showWatts = "showWattsInMenuBar"
        static let showPercentage = "showPercentageInMenuBar"
        static let launchAtLogin = "launchAtLogin"
        static let popoverTheme = "popoverTheme"
        static let fontSize = "fontSizePreference"
        static let uiScale = "uiScalePreference"
        static let increaseContrast = "a11yIncreaseContrast"
        static let boldText = "a11yBoldText"
        static let reduceTransparency = "a11yReduceTransparency"
        static let differentiateWithoutColor = "a11yDifferentiateWithoutColor"
        static let menuBarStyle = "menuBarStyle"
    }

    private let defaults: UserDefaults
    private var isSyncingLaunchAtLogin = false

    var refreshIntervalSeconds: Double {
        didSet {
            let clamped = AppSettings.clampedInterval(refreshIntervalSeconds)
            if clamped != refreshIntervalSeconds {
                refreshIntervalSeconds = clamped
                return
            }
            defaults.set(clamped, forKey: Keys.refreshInterval)
        }
    }

    var showWattsInMenuBar: Bool {
        didSet { defaults.set(showWattsInMenuBar, forKey: Keys.showWatts) }
    }

    var showPercentageInMenuBar: Bool {
        didSet { defaults.set(showPercentageInMenuBar, forKey: Keys.showPercentage) }
    }

    var launchAtLogin: Bool {
        didSet {
            guard !isSyncingLaunchAtLogin else { return }
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            applyLaunchAtLogin(launchAtLogin)
        }
    }

    var popoverTheme: PopoverTheme {
        didSet { defaults.set(popoverTheme.rawValue, forKey: Keys.popoverTheme) }
    }

    var fontSize: FontSizePreference {
        didSet { defaults.set(fontSize.rawValue, forKey: Keys.fontSize) }
    }

    var uiScale: UIScalePreference {
        didSet { defaults.set(uiScale.rawValue, forKey: Keys.uiScale) }
    }

    var increaseContrast: Bool {
        didSet { defaults.set(increaseContrast, forKey: Keys.increaseContrast) }
    }

    var boldText: Bool {
        didSet { defaults.set(boldText, forKey: Keys.boldText) }
    }

    var reduceTransparency: Bool {
        didSet { defaults.set(reduceTransparency, forKey: Keys.reduceTransparency) }
    }

    var differentiateWithoutColor: Bool {
        didSet { defaults.set(differentiateWithoutColor, forKey: Keys.differentiateWithoutColor) }
    }

    var menuBarStyle: MenuBarStyle {
        didSet { defaults.set(menuBarStyle.rawValue, forKey: Keys.menuBarStyle) }
    }

    /// Curated size control; writes through to fontSize + uiScale.
    var displaySize: DisplaySizePreference {
        get { DisplaySizePreference.matching(fontSize: fontSize, uiScale: uiScale) }
        set {
            fontSize = newValue.fontSize
            uiScale = newValue.uiScale
        }
    }

    var accessibility: AccessibilityPreferences {
        AccessibilityPreferences(
            increaseContrast: increaseContrast,
            boldText: boldText,
            reduceTransparency: reduceTransparency,
            differentiateWithoutColor: differentiateWithoutColor
        )
    }

    var settings: AppSettings {
        AppSettings(
            refreshIntervalSeconds: refreshIntervalSeconds,
            showWattsInMenuBar: showWattsInMenuBar,
            showPercentageInMenuBar: showPercentageInMenuBar,
            launchAtLogin: launchAtLogin,
            popoverTheme: popoverTheme,
            fontSize: fontSize,
            uiScale: uiScale,
            accessibility: accessibility,
            menuBarStyle: menuBarStyle
        )
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedInterval: Double
        if let doubleValue = defaults.object(forKey: Keys.refreshInterval) as? Double {
            storedInterval = doubleValue
        } else if let intValue = defaults.object(forKey: Keys.refreshInterval) as? Int {
            storedInterval = Double(intValue)
        } else {
            storedInterval = AppSettings.default.refreshIntervalSeconds
        }
        self.refreshIntervalSeconds = AppSettings.clampedInterval(storedInterval)

        if defaults.object(forKey: Keys.showWatts) == nil {
            self.showWattsInMenuBar = AppSettings.default.showWattsInMenuBar
        } else {
            self.showWattsInMenuBar = defaults.bool(forKey: Keys.showWatts)
        }

        if defaults.object(forKey: Keys.showPercentage) == nil {
            self.showPercentageInMenuBar = AppSettings.default.showPercentageInMenuBar
        } else {
            self.showPercentageInMenuBar = defaults.bool(forKey: Keys.showPercentage)
        }

        if let raw = defaults.string(forKey: Keys.popoverTheme),
           let theme = PopoverTheme(rawValue: raw) {
            self.popoverTheme = theme
        } else {
            self.popoverTheme = AppSettings.default.popoverTheme
        }

        if let raw = defaults.string(forKey: Keys.fontSize),
           let size = FontSizePreference(rawValue: raw) {
            self.fontSize = size
        } else {
            self.fontSize = AppSettings.default.fontSize
        }

        if let raw = defaults.string(forKey: Keys.uiScale),
           let scale = UIScalePreference(rawValue: raw) {
            self.uiScale = scale
        } else {
            self.uiScale = AppSettings.default.uiScale
        }

        self.increaseContrast = defaults.object(forKey: Keys.increaseContrast) == nil
            ? AccessibilityPreferences.default.increaseContrast
            : defaults.bool(forKey: Keys.increaseContrast)
        self.boldText = defaults.object(forKey: Keys.boldText) == nil
            ? AccessibilityPreferences.default.boldText
            : defaults.bool(forKey: Keys.boldText)
        self.reduceTransparency = defaults.object(forKey: Keys.reduceTransparency) == nil
            ? AccessibilityPreferences.default.reduceTransparency
            : defaults.bool(forKey: Keys.reduceTransparency)
        self.differentiateWithoutColor = defaults.object(forKey: Keys.differentiateWithoutColor) == nil
            ? AccessibilityPreferences.default.differentiateWithoutColor
            : defaults.bool(forKey: Keys.differentiateWithoutColor)

        let migratedStyle = MenuBarStyle.migrating(fromRaw: defaults.string(forKey: Keys.menuBarStyle))
        self.menuBarStyle = migratedStyle
        defaults.set(migratedStyle.rawValue, forKey: Keys.menuBarStyle)

        let serviceEnabled = SMAppService.mainApp.status == .enabled
        self.isSyncingLaunchAtLogin = true
        self.launchAtLogin = serviceEnabled
        self.isSyncingLaunchAtLogin = false
        defaults.set(serviceEnabled, forKey: Keys.launchAtLogin)
    }

    func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            let actual = SMAppService.mainApp.status == .enabled
            guard launchAtLogin != actual else { return }
            isSyncingLaunchAtLogin = true
            launchAtLogin = actual
            defaults.set(actual, forKey: Keys.launchAtLogin)
            isSyncingLaunchAtLogin = false
        }
    }

    /// Restores every preference to `AppSettings.default` and persists.
    func resetToDefaults() {
        let defaultsSettings = AppSettings.default

        refreshIntervalSeconds = defaultsSettings.refreshIntervalSeconds
        showWattsInMenuBar = defaultsSettings.showWattsInMenuBar
        showPercentageInMenuBar = defaultsSettings.showPercentageInMenuBar
        popoverTheme = defaultsSettings.popoverTheme
        fontSize = defaultsSettings.fontSize
        uiScale = defaultsSettings.uiScale
        increaseContrast = defaultsSettings.accessibility.increaseContrast
        boldText = defaultsSettings.accessibility.boldText
        reduceTransparency = defaultsSettings.accessibility.reduceTransparency
        differentiateWithoutColor = defaultsSettings.accessibility.differentiateWithoutColor
        menuBarStyle = defaultsSettings.menuBarStyle

        // Launch at Login last so SMAppService matches the default (off).
        if launchAtLogin != defaultsSettings.launchAtLogin {
            launchAtLogin = defaultsSettings.launchAtLogin
        } else {
            defaults.set(defaultsSettings.launchAtLogin, forKey: Keys.launchAtLogin)
            applyLaunchAtLogin(defaultsSettings.launchAtLogin)
        }
    }
}
