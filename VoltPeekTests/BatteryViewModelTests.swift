import XCTest
@testable import VoltPeek

final class BatteryViewModelTests: XCTestCase {
    func testTimeRemainingLabelFullyCharged() {
        var battery = BatteryInfo.unavailable
        battery.percentage = 100
        battery.isOnACPower = true
        battery.isCharging = false
        battery.isFullyCharged = true
        battery.timeRemaining = nil

        XCTAssertEqual(
            BatteryViewModel.timeRemainingLabel(for: battery),
            "Fully charged"
        )
    }

    func testTimeRemainingLabelOnACNotCharging() {
        var battery = BatteryInfo.unavailable
        battery.percentage = 80
        battery.isOnACPower = true
        battery.isCharging = false
        battery.isFullyCharged = false
        battery.timeRemaining = nil

        XCTAssertEqual(
            BatteryViewModel.timeRemainingLabel(for: battery),
            "On AC power"
        )
    }

    func testTimeRemainingLabelUsesEstimateWhenPresent() {
        var battery = BatteryInfo.unavailable
        battery.isCharging = true
        battery.timeRemaining = "1 h 20 min"

        XCTAssertEqual(
            BatteryViewModel.timeRemainingLabel(for: battery),
            "1 h 20 min"
        )
    }

    func testTimeRemainingLabelCalculatingWhileDischarging() {
        var battery = BatteryInfo.unavailable
        battery.percentage = 55
        battery.isOnACPower = false
        battery.isCharging = false
        battery.timeRemaining = nil

        XCTAssertEqual(
            BatteryViewModel.timeRemainingLabel(for: battery),
            "Calculating time left…"
        )
    }

    func testTimeRemainingLabelCalculatingWhileCharging() {
        var battery = BatteryInfo.unavailable
        battery.percentage = 40
        battery.isOnACPower = true
        battery.isCharging = true
        battery.timeRemaining = nil

        XCTAssertEqual(
            BatteryViewModel.timeRemainingLabel(for: battery),
            "Calculating time to full…"
        )
    }
}
