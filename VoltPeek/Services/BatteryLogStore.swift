import Foundation

/// Persists compact charging and discharging sessions and owns their transition rules.
@MainActor
@Observable
final class BatteryLogStore {
    static let defaultMaximumEntryCount = 100

    private struct Document: Codable {
        var version = 1
        var entries: [BatteryLogEntry] = []
        var currentEntry: BatteryLogEntry?
    }

    private(set) var entries: [BatteryLogEntry] = []
    private(set) var currentEntry: BatteryLogEntry?

    private let fileManager: FileManager
    private let rootDirectory: URL
    private let maximumEntryCount: Int
    private let persistenceInterval: TimeInterval
    private let minimumUnchangedSessionDuration: TimeInterval = 60
    private var lastPersistedDate: Date?
    private var isSleeping = false

    private var historyFileURL: URL {
        rootDirectory.appendingPathComponent("battery-history.json")
    }

    init(
        fileManager: FileManager = .default,
        rootDirectory: URL? = nil,
        maximumEntryCount: Int = defaultMaximumEntryCount,
        persistenceInterval: TimeInterval = 60
    ) {
        self.fileManager = fileManager
        self.maximumEntryCount = max(1, maximumEntryCount)
        self.persistenceInterval = max(0, persistenceInterval)

        if let rootDirectory {
            self.rootDirectory = rootDirectory
        } else if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            // A hosted XCTest run launches the app target. Keep that process away from
            // the user's real Application Support history.
            self.rootDirectory = fileManager.temporaryDirectory
                .appendingPathComponent(
                    "VoltPeek-TestHistory-\(ProcessInfo.processInfo.processIdentifier)",
                    isDirectory: true
                )
        } else {
            let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.rootDirectory = base
                .appendingPathComponent("VoltPeek", isDirectory: true)
                .appendingPathComponent("History", isDirectory: true)
        }

        load()
        recoverInterruptedEntry()
    }

    var allEntriesNewestFirst: [BatteryLogEntry] {
        let values = entries + [currentEntry].compactMap { $0 }
        return values.sorted { $0.startDate > $1.startDate }
    }

    func record(_ battery: BatteryInfo, at date: Date = Date()) {
        guard !isSleeping, isValid(battery) else { return }

        let nextKind = kind(for: battery)
        guard let currentEntry else {
            guard let nextKind else { return }
            start(kind: nextKind, battery: battery, at: date)
            return
        }

        guard nextKind == currentEntry.kind else {
            finishCurrent(
                at: date,
                percentage: battery.percentage,
                reason: .stateChanged
            )
            if let nextKind {
                start(kind: nextKind, battery: battery, at: date)
            }
            return
        }

        let previousPercentage = currentEntry.endPercentage
        self.currentEntry?.endPercentage = battery.percentage
        self.currentEntry?.lastObservedDate = max(currentEntry.lastObservedDate, date)

        if previousPercentage != battery.percentage || shouldPersist(at: date) {
            persist()
            lastPersistedDate = date
        }
    }

    func handleSleep(at date: Date = Date()) {
        isSleeping = true
        finishCurrent(at: date, reason: .sleep)
    }

    func handleWake() {
        isSleeping = false
    }

    func handleAppTermination(at date: Date = Date()) {
        finishCurrent(at: date, reason: .appTermination)
    }

    private func kind(for battery: BatteryInfo) -> BatteryLogKind? {
        if battery.isCharging {
            return .charging
        }
        if !battery.isOnACPower {
            return .discharging
        }
        return nil
    }

    private func isValid(_ battery: BatteryInfo) -> Bool {
        battery != .unavailable && (0...100).contains(battery.percentage)
    }

    private func start(kind: BatteryLogKind, battery: BatteryInfo, at date: Date) {
        currentEntry = BatteryLogEntry(
            kind: kind,
            startDate: date,
            startPercentage: battery.percentage,
            endPercentage: battery.percentage,
            lastObservedDate: date
        )
        prune()
        persist()
        lastPersistedDate = date
    }

    private func finishCurrent(
        at date: Date,
        percentage: Int? = nil,
        reason: BatteryLogCompletionReason
    ) {
        guard var entry = currentEntry else { return }
        let endDate = max(entry.startDate, date)
        entry.endDate = endDate
        entry.lastObservedDate = endDate
        if let percentage {
            entry.endPercentage = percentage
        }
        entry.completionReason = reason
        if shouldKeep(entry) {
            entries.append(entry)
        }
        currentEntry = nil
        prune()
        persist()
        lastPersistedDate = date
    }

    private func recoverInterruptedEntry() {
        guard var entry = currentEntry else { return }
        entry.endDate = max(entry.startDate, entry.lastObservedDate)
        entry.completionReason = .interrupted
        if shouldKeep(entry) {
            entries.append(entry)
        }
        currentEntry = nil
        prune()
        persist()
    }

    private func shouldPersist(at date: Date) -> Bool {
        guard let lastPersistedDate else { return true }
        return date.timeIntervalSince(lastPersistedDate) >= persistenceInterval
    }

    private func prune() {
        let completedEntryLimit = max(
            0,
            maximumEntryCount - (currentEntry == nil ? 0 : 1)
        )
        guard entries.count > completedEntryLimit else { return }
        entries.sort { $0.startDate < $1.startDate }
        entries.removeFirst(entries.count - completedEntryLimit)
    }

    private func shouldKeep(_ entry: BatteryLogEntry) -> Bool {
        guard entry.startPercentage == entry.endPercentage else { return true }
        let endDate = entry.endDate ?? entry.lastObservedDate
        return endDate.timeIntervalSince(entry.startDate) >= minimumUnchangedSessionDuration
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard
            fileManager.fileExists(atPath: historyFileURL.path),
            let data = try? Data(contentsOf: historyFileURL),
            let document = try? decoder.decode(Document.self, from: data),
            document.version == 1
        else {
            return
        }
        entries = document.entries.filter(shouldKeep)
        currentEntry = document.currentEntry
        prune()
    }

    private func persist() {
        do {
            try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
            let document = Document(entries: entries, currentEntry: currentEntry)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.sortedKeys]
            let data = try encoder.encode(document)
            try data.write(to: historyFileURL, options: .atomic)
        } catch {
            AppDiagnostics.shared.log("Unable to persist battery history: \(error.localizedDescription)")
        }
    }
}
