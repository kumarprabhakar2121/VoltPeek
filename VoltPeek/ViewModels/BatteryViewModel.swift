import Foundation
import SwiftUI
import AppKit

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
    private(set) var batteryLogEntries: [BatteryLogEntry] = []
    /// Bumps on every successful poll so MenuBarExtra labels can `.id` against it.
    private(set) var menuBarEpoch: UInt64 = 0
    var onPowerAlert: ((PowerAlertEvent) -> Void)?

    private var intervalObservationTask: Task<Void, Never>?
    private var sleepObservationTask: Task<Void, Never>?
    private var wakeObservationTask: Task<Void, Never>?
    private var terminationObservationTask: Task<Void, Never>?
    private var powerAlertDetector = PowerAlertTransitionDetector()
    private var isStarted = false

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
        guard !isStarted else { return }
        isStarted = true
        AppDiagnostics.shared.log(
            "Battery monitoring started (refresh every \(settingsManager.refreshIntervalSeconds)s)"
        )
        batteryService.startPolling(intervalSeconds: settingsManager.refreshIntervalSeconds)
        observeLifecycle()
        intervalObservationTask?.cancel()
        intervalObservationTask = Task { [weak self] in
            var lastInterval = self?.settingsManager.refreshIntervalSeconds
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self, !Task.isCancelled else { break }
                let current = self.settingsManager.refreshIntervalSeconds
                if current != lastInterval {
                    lastInterval = current
                    AppDiagnostics.shared.log("Refresh interval changed to \(current)s")
                    self.batteryService.startPolling(intervalSeconds: current)
                }
            }
        }
    }

    private func pullFromService() {
        let latestBattery = batteryService.battery
        battery = latestBattery
        charger = batteryService.charger
        wattageHistory = batteryService.wattageHistory
        batteryLogEntries = batteryService.batteryLogStore.allEntriesNewestFirst
        menuBarEpoch &+= 1
        if let event = powerAlertDetector.consume(latestBattery) {
            onPowerAlert?(event)
        }
    }

    private func observeLifecycle() {
        sleepObservationTask = Task { [weak self] in
            for await _ in NSWorkspace.shared.notificationCenter.notifications(
                named: NSWorkspace.willSleepNotification
            ) {
                guard !Task.isCancelled else { break }
                self?.handleSleep()
            }
        }
        wakeObservationTask = Task { [weak self] in
            for await _ in NSWorkspace.shared.notificationCenter.notifications(
                named: NSWorkspace.didWakeNotification
            ) {
                guard !Task.isCancelled else { break }
                self?.handleWake()
            }
        }
        terminationObservationTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(
                named: NSApplication.willTerminateNotification
            ) {
                guard !Task.isCancelled else { break }
                self?.batteryService.batteryLogStore.handleAppTermination()
                self?.pullFromService()
            }
        }
    }

    func handleSleep(at date: Date = Date()) {
        batteryService.batteryLogStore.handleSleep(at: date)
        pullFromService()
    }

    func handleWake() {
        batteryService.batteryLogStore.handleWake()
        batteryService.forceRefresh()
    }

    func resetPowerAlertBaseline() {
        powerAlertDetector.reset()
    }

    /// Signed watts string for Watts / Both menu bar styles.
    var menuBarWattsText: String {
        guard let watts = battery.watts else { return "—" }
        let sign = watts > 0 ? "+" : ""
        return String(format: "%@%.0fW", sign, watts)
    }

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

    /// Time-to-full / time-to-empty, or a short status when IOKit has no estimate.
    func displayTimeRemaining() -> String {
        Self.timeRemainingLabel(for: battery)
    }

    /// Pure display logic for time remaining (testable without IOKit).
    nonisolated static func timeRemainingLabel(for battery: BatteryInfo) -> String {
        if let value = battery.timeRemaining, !value.isEmpty {
            return value
        }
        if battery.isFullyCharged
            || (battery.isOnACPower && !battery.isCharging && battery.percentage >= 100) {
            return "Fully charged"
        }
        if battery.isOnACPower && !battery.isCharging {
            return "On AC power"
        }
        return battery.isCharging ? "Calculating time to full…" : "Calculating time left…"
    }

    /// Clears history and forces a fresh IOKit read into the UI.
    func refreshNow() {
        AppDiagnostics.shared.log("Manual battery refresh requested")
        batteryService.forceRefresh()
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
