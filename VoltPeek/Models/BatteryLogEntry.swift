import Foundation

enum BatteryLogKind: String, Codable, Equatable, Sendable {
    case charging
    case discharging
}

enum BatteryLogCompletionReason: String, Codable, Equatable, Sendable {
    case stateChanged
    case sleep
    case interrupted
    case appTermination
}

struct BatteryLogEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let kind: BatteryLogKind
    let startDate: Date
    var endDate: Date?
    let startPercentage: Int
    var endPercentage: Int
    var lastObservedDate: Date
    var completionReason: BatteryLogCompletionReason?

    init(
        id: UUID = UUID(),
        kind: BatteryLogKind,
        startDate: Date,
        endDate: Date? = nil,
        startPercentage: Int,
        endPercentage: Int,
        lastObservedDate: Date,
        completionReason: BatteryLogCompletionReason? = nil
    ) {
        self.id = id
        self.kind = kind
        self.startDate = startDate
        self.endDate = endDate
        self.startPercentage = startPercentage
        self.endPercentage = endPercentage
        self.lastObservedDate = lastObservedDate
        self.completionReason = completionReason
    }

    var isInProgress: Bool {
        endDate == nil
    }

    func duration(at referenceDate: Date = Date()) -> TimeInterval {
        max(0, (endDate ?? referenceDate).timeIntervalSince(startDate))
    }
}
