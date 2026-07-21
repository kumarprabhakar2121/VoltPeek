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
                Text("Your latest 100 charging and battery-use sessions. Sleep and app restart gaps are excluded.")
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(.secondary)

                if viewModel.batteryLogEntries.isEmpty {
                    emptyState
                } else {
                    TimelineView(.periodic(from: .now, by: 30)) { context in
                        LazyVStack(spacing: 10 * scale) {
                            ForEach(viewModel.batteryLogEntries) { entry in
                                logRow(entry, referenceDate: context.date)
                            }
                        }
                    }
                }
            }
            .padding(22 * scale)
            .frame(maxWidth: 1080 * scale, alignment: .topLeading)
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
        HStack(spacing: 14 * scale) {
            Image(systemName: entry.kind == .charging ? "bolt.fill" : "battery.25")
                .font(.system(size: 15 * scale, weight: .semibold))
                .foregroundStyle(entry.kind == .charging ? Color.green : Color.orange)
                .frame(width: 30 * scale, height: 30 * scale)
                .background(
                    (entry.kind == .charging ? Color.green : Color.orange).opacity(0.14),
                    in: Circle()
                )

            VStack(alignment: .leading, spacing: 4 * scale) {
                HStack(spacing: 7 * scale) {
                    Text(title(for: entry))
                        .font(.system(size: 14 * scale, weight: .semibold))
                        .monospacedDigit()
                    if entry.isInProgress {
                        Text("In progress")
                            .font(.system(size: 10 * scale, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 7 * scale)
                            .padding(.vertical, 3 * scale)
                            .background(Color.accentColor.opacity(0.14), in: Capsule())
                    }
                }
                Text(entry.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11 * scale))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12 * scale)

            Text(durationText(entry.duration(at: referenceDate)))
                .font(.system(size: 14 * scale, weight: .semibold))
                .monospacedDigit()
        }
        .padding(14 * scale)
        .background(
            AppPalette.raisedSurface,
            in: RoundedRectangle(cornerRadius: 11 * scale, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }

    private func title(for entry: BatteryLogEntry) -> String {
        switch entry.kind {
        case .charging:
            return "Charging \(entry.startPercentage)% → \(entry.endPercentage)%"
        case .discharging:
            return "Used \(entry.startPercentage)% → \(entry.endPercentage)%"
        }
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let totalMinutes = max(0, Int(duration) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes) min"
        }
        return "\(minutes) min"
    }
}
