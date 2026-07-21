import CoreGraphics
import XCTest
@testable import VoltPeek

final class PowerAlertPresentationTests: XCTestCase {
    func testPillFrameIsCenteredBelowTopOfVisibleScreen() {
        let screen = CGRect(x: 100, y: 50, width: 1600, height: 1000)

        let frame = PowerAlertLayout.frame(in: screen)

        XCTAssertEqual(frame, CGRect(x: 755, y: 980, width: 290, height: 62))
        XCTAssertEqual(frame.midX, screen.midX)
        XCTAssertEqual(screen.maxY - frame.maxY, 8)
    }

    func testPillFrameClampsToSmallVisibleScreen() {
        let screen = CGRect(x: 100, y: 50, width: 200, height: 50)

        let frame = PowerAlertLayout.frame(in: screen)

        XCTAssertTrue(screen.contains(frame))
        XCTAssertEqual(frame.width, 176)
        XCTAssertEqual(frame.height, 34)
    }

    func testScreenSelectionUsesKeyThenPointerThenBuiltInThenMain() {
        let fallback = descriptor(id: 1)
        let main = descriptor(id: 2, isMain: true)
        let builtIn = descriptor(id: 3, isBuiltIn: true)
        let pointer = descriptor(id: 4, containsPointer: true)
        let key = descriptor(id: 5, isKey: true)

        XCTAssertEqual(
            PowerAlertScreenSelection.select(
                from: [fallback, main, builtIn, pointer, key]
            )?.id,
            key.id
        )
        XCTAssertEqual(
            PowerAlertScreenSelection.select(
                from: [fallback, main, builtIn, pointer]
            )?.id,
            pointer.id
        )
        XCTAssertEqual(
            PowerAlertScreenSelection.select(from: [fallback, main, builtIn])?.id,
            builtIn.id
        )
        XCTAssertEqual(
            PowerAlertScreenSelection.select(from: [fallback, main])?.id,
            main.id
        )
    }

    func testNewPresentationInvalidatesOlderDismissal() {
        var generation = PowerAlertPresentationGeneration()
        let first = generation.next()
        let second = generation.next()

        XCTAssertFalse(generation.isCurrent(first))
        XCTAssertTrue(generation.isCurrent(second))
    }

    private func descriptor(
        id: CGDirectDisplayID,
        isKey: Bool = false,
        containsPointer: Bool = false,
        isBuiltIn: Bool = false,
        isMain: Bool = false
    ) -> PowerAlertScreenDescriptor {
        PowerAlertScreenDescriptor(
            id: id,
            visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800),
            isKey: isKey,
            containsPointer: containsPointer,
            isBuiltIn: isBuiltIn,
            isMain: isMain
        )
    }
}
