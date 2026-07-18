import SwiftUI

/// Shared formatters and adapter copy used across popover themes.
enum ThemeContentHelpers {
    /// Wattage · name when connected; `nil` when unplugged (caller shows a single empty state).
    @MainActor
    static func adapterDetail(viewModel: BatteryViewModel) -> String? {
        guard viewModel.charger.connected else { return nil }
        var parts: [String] = []
        if let w = viewModel.charger.adapterWatts {
            parts.append(viewModel.displayWatts(w))
        }
        if let name = viewModel.charger.adapterName, !name.isEmpty {
            parts.append(name)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    static func capacityText(_ value: Int?) -> String {
        guard let value else { return "Unavailable" }
        return "\(value) mAh"
    }
}
