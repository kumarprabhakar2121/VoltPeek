import Foundation

/// Snapshot of power adapter / charger state.
struct ChargerInfo: Equatable, Sendable {
    var connected: Bool
    var adapterName: String?
    var adapterWatts: Double?
    /// Adapter output voltage in volts when available.
    var adapterVoltage: Double?
    /// Adapter output current in amperes when available.
    var adapterAmperage: Double?
    var adapterManufacturer: String?

    static let unavailable = ChargerInfo(
        connected: false,
        adapterName: nil,
        adapterWatts: nil,
        adapterVoltage: nil,
        adapterAmperage: nil,
        adapterManufacturer: nil
    )
}
