import XCTest
@testable import VoltPeek

final class PowerAlertTransitionDetectorTests: XCTestCase {
    func testFirstValidSnapshotSeedsWithoutAlertAndRepeatedStateIsSilent() {
        var detector = PowerAlertTransitionDetector()
        let charging = battery(percentage: 42, isCharging: true, isOnACPower: true)

        XCTAssertNil(detector.consume(charging))
        XCTAssertNil(detector.consume(charging))
    }

    func testChargingAndUnpluggedTransitionsEmitOnce() {
        var detector = PowerAlertTransitionDetector()
        XCTAssertNil(detector.consume(battery(percentage: 40, isOnACPower: false)))

        XCTAssertEqual(
            detector.consume(
                battery(
                    percentage: 41,
                    isCharging: true,
                    isOnACPower: true,
                    timeRemaining: "45 min"
                )
            ),
            .charging(percentage: 41, timeRemaining: "45 min")
        )
        XCTAssertNil(
            detector.consume(battery(percentage: 42, isCharging: true, isOnACPower: true))
        )
        XCTAssertEqual(
            detector.consume(battery(percentage: 42, isOnACPower: false)),
            .unplugged(percentage: 42, timeRemaining: nil)
        )
    }

    func testFullyChargedEmitsButACIdlePauseDoesNot() {
        var detector = PowerAlertTransitionDetector()
        XCTAssertNil(
            detector.consume(battery(percentage: 98, isCharging: true, isOnACPower: true))
        )
        XCTAssertNil(
            detector.consume(battery(percentage: 99, isOnACPower: true))
        )
        XCTAssertEqual(
            detector.consume(
                battery(
                    percentage: 100,
                    isOnACPower: true,
                    isFullyCharged: true
                )
            ),
            .fullyCharged(percentage: 100, timeRemaining: nil)
        )
        XCTAssertNil(
            detector.consume(
                battery(
                    percentage: 100,
                    isOnACPower: true,
                    isFullyCharged: true
                )
            )
        )
    }

    func testUnavailableReadResetsBaselineWithoutRecoveryAlert() {
        var detector = PowerAlertTransitionDetector()
        XCTAssertNil(detector.consume(battery(percentage: 60, isOnACPower: false)))
        XCTAssertNil(detector.consume(.unavailable))
        XCTAssertNil(
            detector.consume(battery(percentage: 61, isCharging: true, isOnACPower: true))
        )
    }

    func testLowBatteryEmitsWhenDischargingCrossesTwentyPercent() {
        var detector = PowerAlertTransitionDetector()
        XCTAssertNil(
            detector.consume(
                battery(
                    percentage: 21,
                    isOnACPower: false,
                    timeRemaining: "1 h 10 min"
                )
            )
        )

        XCTAssertEqual(
            detector.consume(
                battery(
                    percentage: 20,
                    isOnACPower: false,
                    timeRemaining: "1 h 5 min"
                )
            ),
            .lowBattery(percentage: 20, timeRemaining: "1 h 5 min")
        )
        XCTAssertNil(
            detector.consume(
                battery(
                    percentage: 19,
                    isOnACPower: false,
                    timeRemaining: "1 h"
                )
            )
        )
    }

    private func battery(
        percentage: Int,
        isCharging: Bool = false,
        isOnACPower: Bool,
        isFullyCharged: Bool = false,
        timeRemaining: String? = nil
    ) -> BatteryInfo {
        var battery = BatteryInfo.unavailable
        battery.percentage = percentage
        battery.isCharging = isCharging
        battery.isOnACPower = isOnACPower
        battery.isFullyCharged = isFullyCharged
        battery.timeRemaining = timeRemaining
        battery.voltage = 12
        return battery
    }
}
