import XCTest
@testable import VoltPeek

final class AppSettingsTests: XCTestCase {
    func testDisplaySizeMappingPairs() {
        XCTAssertEqual(DisplaySizePreference.compact.fontSize, .small)
        XCTAssertEqual(DisplaySizePreference.compact.uiScale, .compact85)
        XCTAssertEqual(DisplaySizePreference.standard.fontSize, .medium)
        XCTAssertEqual(DisplaySizePreference.standard.uiScale, .standard)
        XCTAssertEqual(DisplaySizePreference.large.fontSize, .large)
        XCTAssertEqual(DisplaySizePreference.large.uiScale, .large115)
        XCTAssertEqual(DisplaySizePreference.extraLarge.fontSize, .large)
        XCTAssertEqual(DisplaySizePreference.extraLarge.uiScale, .xlarge130)
    }

    func testDisplaySizeMatchingExactAndFallback() {
        XCTAssertEqual(
            DisplaySizePreference.matching(fontSize: .medium, uiScale: .standard),
            .standard
        )
        XCTAssertEqual(
            DisplaySizePreference.matching(fontSize: .small, uiScale: .compact85),
            .compact
        )
        // Mismatched pair falls back by uiScale.
        XCTAssertEqual(
            DisplaySizePreference.matching(fontSize: .small, uiScale: .xlarge130),
            .extraLarge
        )
    }

    func testRefreshIntervalOptionsCoverHalfSecondToTen() {
        XCTAssertEqual(AppSettings.refreshIntervalOptions.first, 0.5)
        XCTAssertEqual(AppSettings.refreshIntervalOptions.last, 10)
        XCTAssertTrue(AppSettings.refreshIntervalOptions.contains(3))
    }

    func testAppScaleUsesTwentyPercentSteps() {
        XCTAssertEqual(AppSettings.appScaleOptions, [80, 100, 120, 140, 160, 180, 200])
        XCTAssertEqual(AppSettings.clampedAppScale(70), 80)
        XCTAssertEqual(AppSettings.clampedAppScale(138), 140)
        XCTAssertEqual(AppSettings.clampedAppScale(220), 200)
        XCTAssertEqual(AppSettings.default.appScalePercent, 100)
    }

    func testAppScaleClampingHandlesExtremeStoredValues() {
        XCTAssertEqual(AppSettings.clampedAppScale(Int.min), 80)
        XCTAssertEqual(AppSettings.clampedAppScale(Int.max), 200)
    }

    func testPopoverThemeTitles() {
        XCTAssertEqual(PopoverTheme.compact.title, "List")
        XCTAssertEqual(PopoverTheme.material.title, "Cards")
        XCTAssertEqual(PopoverTheme.liquidGlass.title, "Glass")
    }

    func testMenuBarStyleOptions() {
        XCTAssertEqual(MenuBarStyle.allCases.map(\.rawValue), ["battery", "watts", "both", "hidden"])
        XCTAssertEqual(MenuBarStyle.battery.title, "Battery")
        XCTAssertEqual(MenuBarStyle.watts.title, "Watts")
        XCTAssertEqual(MenuBarStyle.both.title, "Both")
        XCTAssertEqual(MenuBarStyle.hidden.title, "Hidden")
        XCTAssertEqual(AppSettings.default.menuBarStyle, .battery)
    }

    func testMenuBarBatteryAppearanceOptions() {
        XCTAssertEqual(MenuBarBatteryAppearance.allCases.map(\.rawValue), ["colored", "monochrome"])
        XCTAssertEqual(MenuBarBatteryAppearance.colored.title, "Colored")
        XCTAssertEqual(MenuBarBatteryAppearance.monochrome.title, "Black & White")
        XCTAssertEqual(AppSettings.default.menuBarBatteryAppearance, .colored)
    }

    func testPowerStatusPillDefaultsToVisualsAndGentleSoundsEnabled() {
        XCTAssertTrue(AppSettings.default.powerStatusPillEnabled)
        XCTAssertTrue(AppSettings.default.powerStatusPillSoundsEnabled)
    }

    func testMenuBarStyleMigrationFromLegacyRawValues() {
        XCTAssertEqual(MenuBarStyle.migrating(fromRaw: nil), .battery)
        XCTAssertEqual(MenuBarStyle.migrating(fromRaw: "battery"), .battery)
        XCTAssertEqual(MenuBarStyle.migrating(fromRaw: "watts"), .watts)
        XCTAssertEqual(MenuBarStyle.migrating(fromRaw: "both"), .both)

        XCTAssertEqual(MenuBarStyle.migrating(fromRaw: "batteryPercent"), .battery)
        XCTAssertEqual(MenuBarStyle.migrating(fromRaw: "batteryBolt"), .battery)
        XCTAssertEqual(MenuBarStyle.migrating(fromRaw: "batteryIcon"), .battery)
        XCTAssertEqual(MenuBarStyle.migrating(fromRaw: "iconAndPercent"), .battery)

        XCTAssertEqual(MenuBarStyle.migrating(fromRaw: "boltWatts"), .watts)
        XCTAssertEqual(MenuBarStyle.migrating(fromRaw: "bolt"), .watts)

        XCTAssertEqual(MenuBarStyle.migrating(fromRaw: "text"), .both)
        XCTAssertEqual(MenuBarStyle.migrating(fromRaw: "unknown-legacy"), .battery)
    }
}
