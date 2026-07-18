import Foundation

/// Snapshot of battery state read from IOPowerSources and IOKit.
/// `current` and `watts` are signed: positive while charging into the pack, negative while discharging.
struct BatteryInfo: Equatable, Sendable {
    var percentage: Int
    var isCharging: Bool
    var isOnACPower: Bool
    var currentCapacity: Int?
    var maxCapacity: Int?
    var designCapacity: Int?
    var cycleCount: Int?
    var voltage: Double?
    /// Signed amperes (positive = charge into battery).
    var current: Double?
    /// Signed watts (positive = charging power into battery).
    var watts: Double?
    var health: Double?
    var timeRemaining: String?
    /// Battery temperature in Celsius when available.
    var temperatureCelsius: Double?

    static let unavailable = BatteryInfo(
        percentage: 0,
        isCharging: false,
        isOnACPower: false,
        currentCapacity: nil,
        maxCapacity: nil,
        designCapacity: nil,
        cycleCount: nil,
        voltage: nil,
        current: nil,
        watts: nil,
        health: nil,
        timeRemaining: nil,
        temperatureCelsius: nil
    )
}
