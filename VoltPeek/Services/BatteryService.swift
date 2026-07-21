import Foundation

/// A single wattage sample for the rolling 10-minute graph.
struct WattageSample: Equatable, Sendable {
    let date: Date
    let watts: Double
}

/// Periodically polls `PowerSourceReader` and publishes the latest battery/charger snapshot.
@MainActor
@Observable
final class BatteryService {
    private(set) var battery: BatteryInfo = .unavailable
    private(set) var charger: ChargerInfo = .unavailable
    /// Samples within the last 10 minutes (oldest → newest).
    private(set) var wattageHistory: [WattageSample] = []

    /// Invoked on the main actor after each successful refresh.
    var onUpdate: (() -> Void)?

    private let reader: PowerSourceReader
    private var pollingTask: Task<Void, Never>?
    private var isReading = false
    private let historyWindow: TimeInterval = 10 * 60

    init(reader: PowerSourceReader = PowerSourceReader()) {
        self.reader = reader
    }

    /// Starts (or restarts) polling at the given interval in seconds.
    func startPolling(intervalSeconds: Double) {
        stopPolling()
        let interval = AppSettings.clampedInterval(intervalSeconds)
        refresh()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                self?.refresh()
            }
        }
    }

    /// Cancels the polling loop.
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    /// Performs a single coalesced read from the system.
    func refresh() {
        guard !isReading else { return }
        performRead()
    }

    /// Always re-reads IOKit and appends a fresh sample (manual Refresh).
    func forceRefresh() {
        performRead()
    }

    private func performRead() {
        isReading = true
        defer { isReading = false }

        let snapshot = reader.read()
        battery = snapshot.battery
        charger = snapshot.charger
        appendWattageSample(battery.watts)
        onUpdate?()
    }

    private func appendWattageSample(_ watts: Double?) {
        let now = Date()
        let value = watts ?? 0
        wattageHistory.append(WattageSample(date: now, watts: value))
        let cutoff = now.addingTimeInterval(-historyWindow)
        wattageHistory.removeAll { $0.date < cutoff }
    }
}
