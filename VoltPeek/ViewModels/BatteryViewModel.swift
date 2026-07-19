import Foundation
import SwiftUI

/// Bridges `BatteryService` and `SettingsManager` to the menu bar label and popover.
@MainActor
@Observable
final class BatteryViewModel {
    let batteryService: BatteryService
    let settingsManager: SettingsManager

    /// Mirrored from `BatteryService` so MenuBarExtra / popover observe this object directly.
    private(set) var battery: BatteryInfo = .unavailable
    private(set) var charger: ChargerInfo = .unavailable
    private(set) var wattageHistory: [WattageSample] = []
    private(set) var lastUpdated: Date?
    /// Bumps on every successful poll so MenuBarExtra labels can `.id` against it.
    private(set) var menuBarEpoch: UInt64 = 0

    private var intervalObservationTask: Task<Void, Never>?

    init(
        batteryService: BatteryService? = nil,
        settingsManager: SettingsManager? = nil
    ) {
        self.batteryService = batteryService ?? BatteryService()
        self.settingsManager = settingsManager ?? SettingsManager()
        self.batteryService.onUpdate = { [weak self] in
            self?.pullFromService()
        }
        pullFromService()
    }

    func start() {
        batteryService.startPolling(intervalSeconds: settingsManager.refreshIntervalSeconds)
        intervalObservationTask?.cancel()
        intervalObservationTask = Task { [weak self] in
            var lastInterval = self?.settingsManager.refreshIntervalSeconds
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self, !Task.isCancelled else { break }
                let current = self.settingsManager.refreshIntervalSeconds
                if current != lastInterval {
                    lastInterval = current
                    self.batteryService.startPolling(intervalSeconds: current)
                }
            }
        }
    }

    func stop() {
        intervalObservationTask?.cancel()
        intervalObservationTask = nil
        batteryService.stopPolling()
    }

    private func pullFromService() {
        battery = batteryService.battery
        charger = batteryService.charger
        wattageHistory = batteryService.wattageHistory
        lastUpdated = batteryService.lastUpdated
        menuBarEpoch &+= 1
    }

    /// Battery fill symbol (no bolt).
    var menuBarBatteryFillSymbolName: String {
        let pct = max(0, min(100, battery.percentage))
        switch pct {
        case ...5: return "battery.0percent"
        case 6...24: return "battery.25percent"
        case 25...49: return "battery.50percent"
        case 50...74: return "battery.75percent"
        default: return "battery.100percent"
        }
    }

    /// Symbol for the active menu bar style.
    var menuBarSymbolName: String? {
        switch settingsManager.menuBarStyle {
        case .text:
            return nil
        case .battery, .batteryPercent:
            return menuBarBatteryFillSymbolName
        case .bolt, .boltWatts:
            return "bolt.fill"
        case .batteryBolt:
            return battery.isCharging ? "battery.100percent.bolt" : menuBarBatteryFillSymbolName
        }
    }

    /// Text beside the menu bar icon (may be empty).
    var menuBarAccessoryText: String {
        switch settingsManager.menuBarStyle {
        case .text:
            return menuBarTitleText
        case .battery, .bolt:
            return ""
        case .batteryPercent, .batteryBolt:
            return "\(battery.percentage)%"
        case .boltWatts:
            if let watts = battery.watts {
                let sign = watts > 0 ? "+" : ""
                return String(format: "%@%.0fW", sign, watts)
            }
            return "—"
        }
    }

    /// Legacy combined title for text-only mode.
    var menuBarText: String { menuBarAccessoryText.isEmpty ? " " : menuBarAccessoryText }

    private var menuBarTitleText: String {
        let showWatts = settingsManager.showWattsInMenuBar
        let showPercent = settingsManager.showPercentageInMenuBar
        let watts = battery.watts

        var parts: [String] = []

        if showWatts, let watts {
            let sign = watts >= 0 ? "+" : ""
            parts.append(String(format: "⚡ %@%.0fW", sign, watts))
        }

        if showPercent {
            parts.append(String(format: "🔋 %d%%", battery.percentage))
        }

        if parts.isEmpty {
            if let watts {
                let sign = watts >= 0 ? "+" : ""
                return String(format: "⚡ %@%.0fW", sign, watts)
            }
            return String(format: "🔋 %d%%", battery.percentage)
        }

        return parts.joined(separator: " ")
    }

    var menuBarTitle: String { menuBarText }

    // MARK: - Display helpers

    func display(_ value: Int?) -> String {
        guard let value else { return "Unavailable" }
        return "\(value)"
    }

    func displayPercent(_ value: Int) -> String {
        "\(value)%"
    }

    func displayHealth(_ value: Double?) -> String {
        guard let value else { return "Unavailable" }
        return String(format: "%.0f%%", value)
    }

    func displayWatts(_ value: Double?) -> String {
        guard let value else { return "Unavailable" }
        return String(format: "%.0f W", value)
    }

    func displaySignedWatts(_ value: Double?) -> String {
        guard let value else { return "Unavailable" }
        let sign = value > 0 ? "+" : ""
        return String(format: "%@%.0f W", sign, value)
    }

    func displayVoltage(_ value: Double?) -> String {
        guard let value else { return "Unavailable" }
        return String(format: "%.2f V", value)
    }

    func displayCurrent(_ value: Double?) -> String {
        displaySignedCurrent(value)
    }

    func displaySignedCurrent(_ value: Double?) -> String {
        guard let value else { return "Unavailable" }
        let sign = value > 0 ? "+" : ""
        if abs(value) < 1.0 {
            return String(format: "%@%.0f mA", sign, value * 1000)
        }
        return String(format: "%@%.2f A", sign, value)
    }

    func displayTemperature(_ value: Double?) -> String {
        guard let value else { return "Unavailable" }
        return String(format: "%.1f°C", value)
    }

    func temperatureColor(_ value: Double?) -> Color {
        if settingsManager.differentiateWithoutColor { return .primary }
        guard let value else { return .secondary }
        if value < 35 { return Color(red: 0.20, green: 0.70, blue: 0.85) }
        if value <= 42 { return .orange }
        return .red
    }

    func signedPowerColor(_ watts: Double?) -> Color {
        if settingsManager.differentiateWithoutColor { return .primary }
        guard let watts else { return .secondary }
        if watts > 0.05 { return Color(red: 0.043, green: 0.561, blue: 0.416) }
        if watts < -0.05 { return .orange }
        return .secondary
    }

    func signedCurrentColor(_ current: Double?) -> Color {
        if settingsManager.differentiateWithoutColor { return .primary }
        guard let current else { return .secondary }
        if current > 0.001 { return Color(red: 0.043, green: 0.561, blue: 0.416) }
        if current < -0.001 { return .orange }
        return .secondary
    }

    func displayOptionalString(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "Unavailable" }
        return value
    }

    /// Time-to-full / time-to-empty, or a short calculating message when IOKit has no estimate.
    func displayTimeRemaining() -> String {
        if let value = battery.timeRemaining, !value.isEmpty {
            return value
        }
        return battery.isCharging ? "Calculating time to full…" : "Calculating time left…"
    }

    /// Clears history and forces a fresh IOKit read into the UI.
    func refreshNow() {
        batteryService.forceRefresh()
    }

    /// Wear as percent lost from design (from health, or max/design).
    var wearPercent: Double? {
        if let health = battery.health {
            return Swift.max(0, 100.0 - health)
        }
        guard let maxCapacity = battery.maxCapacity,
              let design = battery.designCapacity,
              design > 0 else {
            return nil
        }
        return Swift.max(0, (1.0 - Double(maxCapacity) / Double(design)) * 100.0)
    }

    func displayWear(_ value: Double?) -> String {
        guard let value else { return "Unavailable" }
        return String(format: "%.0f%%", value)
    }

    /// `Now current · Max max mAh` when both capacities exist.
    var displayCapacityPair: String? {
        guard let current = battery.currentCapacity, let max = battery.maxCapacity else { return nil }
        return "Now \(current) · Max \(max) mAh"
    }

    var chargingStatusText: String {
        if battery.isFullyCharged || (battery.isOnACPower && !battery.isCharging && battery.percentage >= 100) {
            return "Fully Charged"
        }
        if battery.isCharging {
            return "Charging"
        }
        if battery.isOnACPower {
            return "On AC Power (not charging)"
        }
        return "Discharging"
    }
}
