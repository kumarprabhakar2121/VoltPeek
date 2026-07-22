import SwiftUI

struct BatteryLogView: View {
    @Bindable var viewModel: BatteryViewModel
    @Environment(\.appScale) private var scale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16 * scale) {
                HStack(spacing: 8 * scale) {
                    Text("Battery Log")
                        .font(.system(size: 22 * scale, weight: .bold))
                    Text("Beta")
                        .font(.system(size: 10 * scale, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 7 * scale)
                        .padding(.vertical, 3 * scale)
                        .background(Color.accentColor.opacity(0.14), in: Capsule())
                }
                Text("Your latest charging and battery-use sessions. Sleep, restarts, and brief blips are excluded.")
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if viewModel.batteryLogEntries.isEmpty {
                    emptyState
                } else {
                    TimelineView(.periodic(from: .now, by: 30)) { context in
                        LazyVStack(spacing: 8 * scale) {
                            ForEach(viewModel.batteryLogEntries) { entry in
                                logRow(entry, referenceDate: context.date)
                            }
                        }
                    }
                }
            }
            .padding(22 * scale)
            .frame(maxWidth: 720 * scale, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .themeEnvironment(
            theme: viewModel.settingsManager.popoverTheme,
            fontSize: viewModel.settingsManager.fontSize,
            uiScale: .standard,
            accessibility: viewModel.settingsManager.accessibility
        )
    }

    private var emptyState: some View {
        VStack(spacing: 10 * scale) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 30 * scale))
                .foregroundStyle(.secondary)
            Text("No battery activity yet")
                .font(.system(size: 15 * scale, weight: .semibold))
            Text("Your next charging or unplugged session will appear here.")
                .font(.system(size: 12 * scale))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48 * scale)
        .background(
            AppPalette.raisedSurface,
            in: RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
        )
    }

    private func logRow(_ entry: BatteryLogEntry, referenceDate: Date) -> some View {
        let accent = kindAccent(for: entry.kind)
        let delta = entry.endPercentage - entry.startPercentage
        let hasVisibleDelta = !(entry.isInProgress && delta == 0)

        return HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 1.5 * scale, style: .continuous)
                .fill(accent)
                .frame(width: 3 * scale)
                .opacity(entry.isInProgress ? 1 : 0)
                .padding(.vertical, 12 * scale)

            VStack(alignment: .leading, spacing: 5 * scale) {
                HStack(alignment: .firstTextBaseline, spacing: 10 * scale) {
                    HStack(spacing: 8 * scale) {
                        Image(systemName: iconName(for: entry))
                            .font(.system(size: 11 * scale, weight: .semibold))
                            .foregroundStyle(accent)
                            .frame(width: 22 * scale, height: 22 * scale)
                            .background(accent.opacity(0.14), in: Circle())

                        Text(kindLabel(for: entry))
                            .font(.system(size: 12 * scale, weight: .bold))
                            .foregroundStyle(accent)
                            .textCase(.uppercase)
                            .tracking(0.35)

                        Text(durationText(entry.duration(at: referenceDate)))
                            .font(.system(size: 15 * scale, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(.primary)

                        if entry.isInProgress {
                            Text("Live")
                                .font(.system(size: 10 * scale, weight: .semibold))
                                .foregroundStyle(accent)
                                .padding(.horizontal, 7 * scale)
                                .padding(.vertical, 3 * scale)
                                .background(accent.opacity(0.14), in: Capsule())
                        }
                    }

                    Spacer(minLength: 8 * scale)

                    Text(hasVisibleDelta ? deltaText(delta) : "—")
                        .font(.system(size: 16 * scale, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(
                            hasVisibleDelta
                                ? deltaAccent(delta, kind: entry.kind)
                                : Color.secondary.opacity(0.7)
                        )
                }

                Text(detailText(for: entry))
                    .font(.system(size: 12 * scale))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .padding(.leading, 30 * scale)
            }
            .padding(.leading, 11 * scale)
            .padding(.trailing, 14 * scale)
            .padding(.vertical, 12 * scale)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppPalette.raisedSurface,
            in: RoundedRectangle(cornerRadius: 11 * scale, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11 * scale, style: .continuous)
                .strokeBorder(
                    entry.isInProgress ? accent.opacity(0.28) : AppPalette.border.opacity(0.55),
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: entry, referenceDate: referenceDate))
    }

    private func kindLabel(for entry: BatteryLogEntry) -> String {
        switch (entry.kind, entry.isInProgress) {
        case (.charging, true): return "Charging"
        case (.charging, false): return "Charged"
        case (.discharging, true): return "Using"
        case (.discharging, false): return "Used"
        }
    }

    private func iconName(for entry: BatteryLogEntry) -> String {
        switch entry.kind {
        case .charging:
            return "bolt.fill"
        case .discharging:
            switch entry.endPercentage {
            case ...25: return "battery.25"
            case ...50: return "battery.50"
            case ...75: return "battery.75"
            default: return "battery.100"
            }
        }
    }

    private func kindAccent(for kind: BatteryLogKind) -> Color {
        switch kind {
        case .charging: return Color.green
        case .discharging: return Color.orange
        }
    }

    private func deltaText(_ delta: Int) -> String {
        if delta > 0 { return "+\(delta)%" }
        if delta < 0 { return "\(delta)%" }
        return "0%"
    }

    private func deltaAccent(_ delta: Int, kind: BatteryLogKind) -> Color {
        if delta > 0 { return .green }
        if delta < 0 { return .orange }
        return kindAccent(for: kind).opacity(0.75)
    }

    private func detailText(for entry: BatteryLogEntry) -> String {
        let stamp = entry.startDate.formatted(date: .abbreviated, time: .shortened)
        return "\(stamp)  ·  \(entry.startPercentage)% to \(entry.endPercentage)%"
    }

    private func accessibilityLabel(for entry: BatteryLogEntry, referenceDate: Date) -> String {
        let kind = kindLabel(for: entry)
        let duration = durationText(entry.duration(at: referenceDate))
        let delta = entry.endPercentage - entry.startPercentage
        let deltaLabel = (entry.isInProgress && delta == 0) ? "no change yet" : deltaText(delta)
        let range = "\(entry.startPercentage) percent to \(entry.endPercentage) percent"
        let progress = entry.isInProgress ? ", live" : ""
        return "\(kind) \(duration), \(deltaLabel), \(range)\(progress)"
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration))
        if totalSeconds < 60 {
            return "< 1 min"
        }

        let totalMinutes = totalSeconds / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            if minutes == 0 {
                return hours == 1 ? "1h" : "\(hours)h"
            }
            return "\(hours)h \(minuteUnit(minutes))"
        }

        return minuteUnit(totalMinutes)
    }

    private func minuteUnit(_ minutes: Int) -> String {
        minutes == 1 ? "1 min" : "\(minutes) mins"
    }
}
