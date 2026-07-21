import XCTest
@testable import VoltPeek

final class InitialWindowLayoutTests: XCTestCase {
    func testInitialWindowUsesThreeQuartersOfVisibleScreenAndIsCentered() {
        let screen = CGRect(x: 100, y: 50, width: 1600, height: 1000)

        let frame = InitialWindowLayout.frame(in: screen)

        XCTAssertEqual(frame, CGRect(x: 300, y: 175, width: 1200, height: 750))
        XCTAssertEqual(frame.midX, screen.midX)
        XCTAssertEqual(frame.midY, screen.midY)
    }
}
