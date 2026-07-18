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

    func testPopoverThemeTitles() {
        XCTAssertEqual(PopoverTheme.compact.title, "List")
        XCTAssertEqual(PopoverTheme.material.title, "Cards")
        XCTAssertEqual(PopoverTheme.liquidGlass.title, "Glass")
    }
}
