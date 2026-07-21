import Foundation

enum PowerAlertEvent: Equatable, Sendable {
    case charging(percentage: Int, timeRemaining: String?)
    case unplugged(percentage: Int, timeRemaining: String?)
    case lowBattery(percentage: Int, timeRemaining: String?)
    case fullyCharged(percentage: Int, timeRemaining: String?)

    var percentage: Int {
        switch self {
        case .charging(let percentage, _),
             .unplugged(let percentage, _),
             .lowBattery(let percentage, _),
             .fullyCharged(let percentage, _):
            return percentage
        }
    }

    var timeRemaining: String? {
        switch self {
        case .charging(_, let timeRemaining),
             .unplugged(_, let timeRemaining),
             .lowBattery(_, let timeRemaining),
             .fullyCharged(_, let timeRemaining):
            return timeRemaining
        }
    }
}

struct PowerAlertTransitionDetector: Sendable {
    private enum State: Equatable, Sendable {
        case onBattery
        case charging
        case fullyCharged
        case acIdle
    }

    private var previousState: State?
    private var wasLowBattery = false

    mutating func consume(_ battery: BatteryInfo) -> PowerAlertEvent? {
        guard battery != .unavailable else {
            previousState = nil
            wasLowBattery = false
            return nil
        }

        let currentState = state(for: battery)
        let isLowBattery = currentState == .onBattery && battery.percentage <= 20
        defer {
            previousState = currentState
            wasLowBattery = isLowBattery
        }

        guard let previousState else {
            return nil
        }

        if isLowBattery && !wasLowBattery {
            return .lowBattery(
                percentage: battery.percentage,
                timeRemaining: battery.timeRemaining
            )
        }

        guard previousState != currentState else { return nil }

        switch currentState {
        case .charging:
            return .charging(
                percentage: battery.percentage,
                timeRemaining: battery.timeRemaining
            )
        case .onBattery:
            return previousState == .onBattery
                ? nil
                : .unplugged(
                    percentage: battery.percentage,
                    timeRemaining: battery.timeRemaining
                )
        case .fullyCharged:
            return .fullyCharged(
                percentage: battery.percentage,
                timeRemaining: battery.timeRemaining
            )
        case .acIdle:
            return nil
        }
    }

    mutating func reset() {
        previousState = nil
        wasLowBattery = false
    }

    private func state(for battery: BatteryInfo) -> State {
        if !battery.isOnACPower {
            return .onBattery
        }
        if battery.isFullyCharged {
            return .fullyCharged
        }
        if battery.isCharging {
            return .charging
        }
        return .acIdle
    }
}
