import XCTest
import IOKit.ps
@testable import VoltPeek

final class PowerSourceReaderTests: XCTestCase {

    func testMapBatteryComputesWattsAndHealth() {
        let powerSource: [String: Any] = [
            kIOPSCurrentCapacityKey: 82,
            kIOPSIsChargingKey: true,
            kIOPSPowerSourceStateKey: kIOPSACPowerValue,
            kIOPSTimeToFullChargeKey: 95
        ]
        let smartBattery: [String: Any] = [
            "Voltage": 12650,          // mV
            "InstantAmperage": 3640,   // mA
            "CycleCount": 312,
            "DesignCapacity": 5000,
            "AppleRawCurrentCapacity": 3690,
            "AppleRawMaxCapacity": 4500,
            "ExternalConnected": true,
            "FullyCharged": false,
            "Manufacturer": "SMP",
            "BatterySerialNumber": "D1234567890",
            "DeviceName": "bq20z451",
            "Temperature": 30915       // centi-Kelvin ≈ 36°C
        ]

        let battery = PowerSourceReader.mapBattery(
            powerSource: powerSource,
            smartBattery: smartBattery
        )

        XCTAssertEqual(battery.percentage, 82)
        XCTAssertTrue(battery.isCharging)
        XCTAssertTrue(battery.isOnACPower)
        XCTAssertFalse(battery.isFullyCharged)
        XCTAssertEqual(battery.cycleCount, 312)
        XCTAssertEqual(battery.designCapacity, 5000)
        XCTAssertEqual(battery.currentCapacity, 3690)
        XCTAssertEqual(battery.maxCapacity, 4500)
        XCTAssertEqual(battery.voltage!, 12.65, accuracy: 0.001)
        XCTAssertEqual(battery.current!, 3.64, accuracy: 0.001)
        XCTAssertEqual(battery.watts!, 12.65 * 3.64, accuracy: 0.05)
        XCTAssertGreaterThan(battery.watts!, 0)
        XCTAssertEqual(battery.health!, 90.0, accuracy: 0.1)
        XCTAssertEqual(battery.timeRemaining, "1 h 35 min")
        XCTAssertEqual(battery.temperatureCelsius!, 36.0, accuracy: 0.2)
        XCTAssertEqual(battery.manufacturer, "SMP")
        XCTAssertEqual(battery.serialNumber, "D1234567890")
        XCTAssertEqual(battery.deviceName, "bq20z451")
    }

    func testMapBatteryFullyChargedFromSmartBattery() {
        let battery = PowerSourceReader.mapBattery(
            powerSource: [
                kIOPSCurrentCapacityKey: 100,
                kIOPSIsChargingKey: false,
                kIOPSPowerSourceStateKey: kIOPSACPowerValue
            ],
            smartBattery: ["FullyCharged": true, "ExternalConnected": true]
        )
        XCTAssertTrue(battery.isFullyCharged)
        XCTAssertTrue(battery.isOnACPower)
        XCTAssertFalse(battery.isCharging)
    }

    func testMapBatterySignedDischargeWatts() {
        let smartBattery: [String: Any] = [
            "Voltage": 12000,
            "InstantAmperage": -1500 // mA discharge
        ]
        let battery = PowerSourceReader.mapBattery(powerSource: [:], smartBattery: smartBattery)
        XCTAssertEqual(battery.current!, -1.5, accuracy: 0.001)
        XCTAssertEqual(battery.watts!, -18.0, accuracy: 0.05)
        XCTAssertLessThan(battery.watts!, 0)
    }

    func testSignedMilliampsTwoComplement() {
        // 64000 as unsigned 16-bit ≈ -1536 mA
        let milli = PowerSourceReader.signedMilliamps(64000)
        XCTAssertEqual(milli!, -1536, accuracy: 0.1)
    }

    func testTemperatureConversion() {
        let c = PowerSourceReader.celsiusFromSmartBatteryTemperature(30915)
        XCTAssertEqual(c!, 36.0, accuracy: 0.2)
        // centi-Celsius
        let c2 = PowerSourceReader.celsiusFromSmartBatteryTemperature(3650)
        XCTAssertEqual(c2!, 36.5, accuracy: 0.2)
        // already Celsius
        let c3 = PowerSourceReader.celsiusFromSmartBatteryTemperature(37.0)
        XCTAssertEqual(c3!, 37.0, accuracy: 0.1)
        XCTAssertNil(PowerSourceReader.celsiusFromSmartBatteryTemperature(nil))
    }

    func testMapChargerReadsNSDictionaryAdapterDetails() {
        let details = NSMutableDictionary()
        details["Name"] = "140W USB-C Power Adapter"
        details["Watts"] = NSNumber(value: 140)
        details["AdapterVoltage"] = NSNumber(value: 28000) // mV
        details["Current"] = NSNumber(value: 5000) // mA
        details["Manufacturer"] = "Apple Inc."

        let smartBattery: [String: Any] = [
            "ExternalConnected": true,
            "AdapterDetails": details
        ]

        let charger = PowerSourceReader.mapCharger(
            powerSource: [:],
            smartBattery: smartBattery
        )

        XCTAssertTrue(charger.connected)
        XCTAssertEqual(charger.adapterName, "140W USB-C Power Adapter")
        XCTAssertEqual(charger.adapterWatts, 140)
        XCTAssertEqual(charger.adapterVoltage!, 28.0, accuracy: 0.01)
        XCTAssertEqual(charger.adapterAmperage!, 5.0, accuracy: 0.01)
        XCTAssertEqual(charger.adapterManufacturer, "Apple Inc.")
    }

    func testMapChargerEstimatesWattsFromBatteryWhenDetailsMissing() {
        let charger = PowerSourceReader.mapCharger(
            powerSource: [:],
            smartBattery: ["ExternalConnected": true],
            batteryWatts: 38.2
        )
        XCTAssertEqual(charger.adapterWatts, 38)
    }

    func testMapBatteryHandlesMissingKeysAsNil() {
        let battery = PowerSourceReader.mapBattery(powerSource: [:], smartBattery: [:])

        XCTAssertEqual(battery.percentage, 0)
        XCTAssertFalse(battery.isCharging)
        XCTAssertFalse(battery.isFullyCharged)
        XCTAssertNil(battery.cycleCount)
        XCTAssertNil(battery.voltage)
        XCTAssertNil(battery.current)
        XCTAssertNil(battery.watts)
        XCTAssertNil(battery.health)
        XCTAssertNil(battery.timeRemaining)
        XCTAssertNil(battery.temperatureCelsius)
        XCTAssertNil(battery.manufacturer)
        XCTAssertNil(battery.serialNumber)
        XCTAssertNil(battery.deviceName)
    }

    func testMapBatteryReportsNegligibleWattsAsZero() {
        let smartBattery: [String: Any] = [
            "Voltage": 12000,
            "Amperage": 2 // 0.002 A → ~0.024 W
        ]
        let battery = PowerSourceReader.mapBattery(powerSource: [:], smartBattery: smartBattery)
        XCTAssertEqual(battery.watts!, 0, accuracy: 0.001)
    }

    func testFormatTimeRemainingMinutesOnly() {
        let text = PowerSourceReader.formatTimeRemaining(
            powerSource: [kIOPSTimeToEmptyKey: 42],
            isCharging: false
        )
        XCTAssertEqual(text, "42 min")
    }

    func testFormatTimeRemainingUnavailableForInvalidMinutes() {
        XCTAssertNil(
            PowerSourceReader.formatTimeRemaining(
                powerSource: [kIOPSTimeToEmptyKey: -1],
                isCharging: false
            )
        )
        XCTAssertNil(
            PowerSourceReader.formatTimeRemaining(
                powerSource: [kIOPSTimeToEmptyKey: 0],
                isCharging: false
            )
        )
    }

    func testMapChargerReadsAdapterDetails() {
        let smartBattery: [String: Any] = [
            "ExternalConnected": true,
            "AdapterDetails": [
                "Name": "USB-C Power Adapter",
                "Watts": 96
            ] as [String: Any]
        ]

        let charger = PowerSourceReader.mapCharger(
            powerSource: [:],
            smartBattery: smartBattery
        )

        XCTAssertTrue(charger.connected)
        XCTAssertEqual(charger.adapterName, "USB-C Power Adapter")
        XCTAssertEqual(charger.adapterWatts, 96)
    }

    func testMapChargerDisconnected() {
        let charger = PowerSourceReader.mapCharger(
            powerSource: [kIOPSPowerSourceStateKey: kIOPSBatteryPowerValue],
            smartBattery: ["ExternalConnected": false]
        )
        XCTAssertFalse(charger.connected)
        XCTAssertNil(charger.adapterWatts)
    }

    func testClampedRefreshInterval() {
        XCTAssertEqual(AppSettings.clampedInterval(0.1), 0.5)
        XCTAssertEqual(AppSettings.clampedInterval(0.5), 0.5)
        XCTAssertEqual(AppSettings.clampedInterval(1), 1)
        XCTAssertEqual(AppSettings.clampedInterval(3), 3)
        XCTAssertEqual(AppSettings.clampedInterval(4), 3)
        XCTAssertEqual(AppSettings.clampedInterval(7), 5)
        XCTAssertEqual(AppSettings.clampedInterval(10), 10)
        XCTAssertEqual(AppSettings.clampedInterval(30), 10)
    }
}
