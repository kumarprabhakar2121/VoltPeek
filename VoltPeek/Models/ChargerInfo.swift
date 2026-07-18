import Foundation

/// Snapshot of power adapter / charger state.
struct ChargerInfo: Equatable, Sendable {
    var connected: Bool
    var adapterName: String?
    var adapterWatts: Double?

    static let unavailable = ChargerInfo(
        connected: false,
        adapterName: nil,
        adapterWatts: nil
    )
}
