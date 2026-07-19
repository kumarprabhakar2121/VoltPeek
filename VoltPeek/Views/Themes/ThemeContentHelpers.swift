import SwiftUI

/// Shared formatters and adapter copy used across popover themes.
enum ThemeContentHelpers {
    /// Wattage · name when connected; `nil` when unplugged (caller shows a single empty state).
    @MainActor
    static func adapterDetail(viewModel: BatteryViewModel) -> String? {
        guard viewModel.charger.connected else { return nil }
        var parts: [String] = []
        if let name = viewModel.charger.adapterName, !name.isEmpty {
            parts.append(name)
        }
        if let w = viewModel.charger.adapterWatts {
            parts.append(viewModel.displayWatts(w))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// Manufacturer when present and not a duplicate of the adapter name.
    @MainActor
    static func adapterManufacturer(viewModel: BatteryViewModel) -> String? {
        guard let manufacturer = viewModel.charger.adapterManufacturer, !manufacturer.isEmpty else {
            return nil
        }
        if let name = viewModel.charger.adapterName,
           name.caseInsensitiveCompare(manufacturer) == .orderedSame {
            return nil
        }
        return manufacturer
    }

    /// Quiet one-liner: health % · cycles · current/max when available.
    @MainActor
    static func passiveHealthSummary(viewModel: BatteryViewModel) -> String {
        var parts: [String] = []
        parts.append(viewModel.displayHealth(viewModel.battery.health))
        parts.append("\(viewModel.display(viewModel.battery.cycleCount)) cycles")
        if let pair = viewModel.displayCapacityPair {
            parts.append(pair)
        }
        return parts.joined(separator: " · ")
    }
}
