import AppKit
import XCTest
@testable import VoltPeek

@MainActor
final class AppLifecycleTests: XCTestCase {
    func testClosingLastWindowKeepsApplicationRunning() {
        let delegate = VoltPeekAppDelegate()

        XCTAssertFalse(
            delegate.applicationShouldTerminateAfterLastWindowClosed(
                NSApplication.shared
            )
        )
    }
}
