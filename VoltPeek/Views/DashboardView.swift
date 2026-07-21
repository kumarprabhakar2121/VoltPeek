import SwiftUI

/// Single app-optimized dashboard. Popover theme choices do not affect this view.
struct DashboardView: View {
    @Bindable var viewModel: BatteryViewModel
    @Environment(\.appScale) private var scale

    private var accent: Color {
        PopoverThemeStyle.statusColor(
            isCharging: viewModel.battery.isCharging,
            isOnACPower: viewModel.battery.isOnACPower
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20 * scale) {
                    heroCard(isWide: geometry.size.width >= 720 * scale)

                    LazyVGrid(
                        columns: metricColumns(for: geometry.size.width),
                        spacing: 14 * scale
                    ) {
                        DashboardMetricCard(
                            title: "Power",
                            value: viewModel.displaySignedWatts(viewModel.battery.watts),
                            systemImage: "bolt.fill",
                            color: viewModel.signedPowerColor(viewModel.battery.watts),
                            scale: scale
                        )
                        DashboardMetricCard(
                            title: "Current",
                            value: viewModel.displaySignedCurrent(viewModel.battery.current),
                            systemImage: "arrow.left.arrow.right",
                            color: viewModel.signedCurrentColor(viewModel.battery.current),
                            scale: scale
                        )
                        DashboardMetricCard(
                            title: "Voltage",
                            value: viewModel.displayVoltage(viewModel.battery.voltage),
                            systemImage: "waveform.path.ecg",
                            scale: scale
                        )
                        DashboardMetricCard(
                            title: "Temperature",
                            value: viewModel.displayTemperature(viewModel.battery.temperatureCelsius),
                            systemImage: "thermometer.medium",
                            color: viewModel.temperatureColor(viewModel.battery.temperatureCelsius),
                            scale: scale
                        )
                    }

                    if geometry.size.width >= 760 * scale {
                        HStack(alignment: .top, spacing: 20 * scale) {
                            healthCard
                                .frame(maxWidth: .infinity)
                            adapterCard
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        VStack(spacing: 20 * scale) {
                            healthCard
                            adapterCard
                        }
                    }
                }
                .frame(maxWidth: 1080 * scale)
                .padding(.horizontal, (geometry.size.width >= 900 * scale ? 36 : 24) * scale)
                .padding(.vertical, 28 * scale)
                .frame(maxWidth: .infinity)
            }
        }
        .background(
            LinearGradient(
                colors: [accent.opacity(0.055), Color.clear],
                startPoint: .topLeading,
                endPoint: .center
            )
        )
        .themeEnvironment(
            theme: .material,
            fontSize: .medium,
            uiScale: .standard,
            accessibility: viewModel.settingsManager.accessibility
        )
    }

    @ViewBuilder
    private func heroCard(isWide: Bool) -> some View {
        DashboardSurface(accent: accent, scale: scale) {
            Group {
                if isWide {
                    HStack(spacing: 28 * scale) {
                        batteryOverview(isHorizontal: true)
                        Divider()
                            .frame(height: 112 * scale)
                        heroDetails
                    }
                } else {
                    VStack(alignment: .leading, spacing: 22 * scale) {
                        batteryOverview(isHorizontal: false)
                        Divider()
                        heroDetails
                    }
                }
            }
            .padding(4 * scale)
        }
    }

    @ViewBuilder
    private func batteryOverview(isHorizontal: Bool) -> some View {
        Group {
            if isHorizontal {
                HStack(spacing: 24 * scale) {
                    batteryRing
                    batterySummary
                    Spacer(minLength: 0)
                }
            } else {
                VStack(alignment: .leading, spacing: 18 * scale) {
                    batteryRing
                    batterySummary
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var batteryRing: some View {
        BatteryRing(
            percentage: viewModel.battery.percentage,
            tint: accent,
            lineWidth: 10 * scale,
            size: 124 * scale
        )
    }

    private var batterySummary: some View {
        VStack(alignment: .leading, spacing: 10 * scale) {
            Text("Mac Battery")
                .font(.system(size: 22 * scale, weight: .bold))
            Text(viewModel.displaySignedWatts(viewModel.battery.watts))
                .font(.system(size: 24 * scale, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(viewModel.signedPowerColor(viewModel.battery.watts))
            DashboardStatusChip(
                text: viewModel.chargingStatusText,
                color: accent,
                scale: scale
            )
        }
    }

    private var heroDetails: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), alignment: .leading),
                GridItem(.flexible(), alignment: .leading)
            ],
            spacing: 18 * scale
        ) {
            HeroDetail(title: "Time remaining", value: viewModel.displayTimeRemaining(), scale: scale)
            HeroDetail(
                title: "Battery health",
                value: viewModel.displayHealth(viewModel.battery.health),
                scale: scale
            )
            HeroDetail(
                title: "Cycle count",
                value: viewModel.display(viewModel.battery.cycleCount),
                scale: scale
            )
            HeroDetail(
                title: "Current capacity",
                value: capacity(viewModel.battery.currentCapacity),
                scale: scale
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var healthCard: some View {
        DashboardSurface(
            title: "Battery Health",
            systemImage: "heart.fill",
            scale: scale
        ) {
            VStack(spacing: 14 * scale) {
                HStack(alignment: .firstTextBaseline) {
                    Text(viewModel.displayHealth(viewModel.battery.health))
                        .font(.system(size: 34 * scale, weight: .bold, design: .rounded))
                    Spacer()
                    Text("\(viewModel.display(viewModel.battery.cycleCount)) cycles")
                        .font(.system(size: 13 * scale))
                        .foregroundStyle(.secondary)
                }

                Divider()

                DashboardInfoRow(
                    label: "Current capacity",
                    value: capacity(viewModel.battery.currentCapacity),
                    scale: scale
                )
                DashboardInfoRow(
                    label: "Maximum capacity",
                    value: capacity(viewModel.battery.maxCapacity),
                    scale: scale
                )
                DashboardInfoRow(
                    label: "Design capacity",
                    value: capacity(viewModel.battery.designCapacity),
                    scale: scale
                )
            }
        }
    }

    private var adapterCard: some View {
        DashboardSurface(
            title: "Power Adapter",
            systemImage: "powerplug.fill",
            scale: scale
        ) {
            VStack(spacing: 14 * scale) {
                HStack {
                    Text(viewModel.charger.connected ? "Connected" : "Unplugged")
                        .font(.system(size: 13 * scale, weight: .semibold))
                    Spacer()
                    Circle()
                        .fill(viewModel.charger.connected ? Color.green : Color.secondary)
                        .frame(width: 9 * scale, height: 9 * scale)
                }

                Divider()

                if viewModel.charger.connected {
                    if let detail = ThemeContentHelpers.adapterDetail(viewModel: viewModel) {
                        DashboardInfoRow(label: "Adapter", value: detail, scale: scale)
                    }
                    DashboardInfoRow(
                        label: "Voltage",
                        value: viewModel.displayVoltage(viewModel.charger.adapterVoltage),
                        scale: scale
                    )
                    DashboardInfoRow(
                        label: "Current",
                        value: viewModel.displayCurrent(viewModel.charger.adapterAmperage),
                        scale: scale
                    )
                    if let manufacturer = ThemeContentHelpers.adapterManufacturer(viewModel: viewModel) {
                        DashboardInfoRow(label: "Manufacturer", value: manufacturer, scale: scale)
                    }
                } else {
                    Text("Connect a power adapter to see charging details.")
                        .font(.system(size: 13 * scale))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func metricColumns(for width: CGFloat) -> [GridItem] {
        let count = width >= 940 * scale ? 4 : width >= 520 * scale ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: 14 * scale), count: count)
    }

    private func capacity(_ value: Int?) -> String {
        guard let value else { return "Unavailable" }
        return "\(value) mAh"
    }
}

private struct DashboardSurface<Content: View>: View {
    var title: String?
    var systemImage: String?
    var accent: Color?
    var scale: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        title: String? = nil,
        systemImage: String? = nil,
        accent: Color? = nil,
        scale: CGFloat,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.accent = accent
        self.scale = scale
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18 * scale) {
            if let title, let systemImage {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 13 * scale, weight: .semibold))
            }
            content()
        }
        .padding(22 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            let shape = RoundedRectangle(cornerRadius: 18 * scale, style: .continuous)
            if let accent {
                shape
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.14), Color(nsColor: .controlBackgroundColor)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.08), radius: 6 * scale, y: 2 * scale)
            } else {
                shape
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.08), radius: 6 * scale, y: 2 * scale)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18 * scale, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        )
    }
}

private struct DashboardMetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    var color: Color = .primary
    let scale: CGFloat

    var body: some View {
        DashboardSurface(scale: scale) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8 * scale) {
                    Text(title)
                        .font(.system(size: 13 * scale))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.system(size: 22 * scale, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Spacer(minLength: 8 * scale)
                Image(systemName: systemImage)
                    .font(.system(size: 16 * scale, weight: .semibold))
                    .foregroundStyle(color.opacity(0.9))
                    .frame(width: 34 * scale, height: 34 * scale)
                    .background(Circle().fill(color.opacity(0.11)))
            }
        }
    }
}

private struct HeroDetail: View {
    let title: String
    let value: String
    let scale: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 5 * scale) {
            Text(title)
                .font(.system(size: 11 * scale))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13 * scale, weight: .semibold))
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct DashboardInfoRow: View {
    let label: String
    let value: String
    let scale: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12 * scale) {
            Text(label)
                .font(.system(size: 13 * scale))
                .foregroundStyle(.secondary)
            Spacer(minLength: 12 * scale)
            Text(value)
                .font(.system(size: 13 * scale))
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct DashboardStatusChip: View {
    let text: String
    let color: Color
    let scale: CGFloat

    var body: some View {
        Text(text)
            .font(.system(size: 12 * scale, weight: .semibold))
            .padding(.horizontal, 9 * scale)
            .padding(.vertical, 4 * scale)
            .foregroundStyle(color)
            .background(Capsule().fill(color.opacity(0.16)))
    }
}
