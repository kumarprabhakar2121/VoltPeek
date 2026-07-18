import SwiftUI

/// Elevated widget cards — one chrome system, teal accent.
struct MaterialPopoverLayout: View {
    @Bindable var viewModel: BatteryViewModel
    @Environment(\.themeScale) private var scale
    @Environment(\.themeProfile) private var profile
    @Environment(\.themeTypography) private var type

    private let powerColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var tint: Color {
        PopoverThemeStyle.statusColor(
            isCharging: viewModel.battery.isCharging,
            isOnACPower: viewModel.battery.isOnACPower
        )
    }

    var body: some View {
        VStack(spacing: profile.sectionSpacing * scale) {
            // Status — ring owns the glance; no eyebrow
            MaterialCard {
                HStack(spacing: 14 * scale) {
                    BatteryRing(
                        percentage: viewModel.battery.percentage,
                        tint: tint,
                        lineWidth: 7 * scale,
                        size: 72 * scale
                    )
                    VStack(alignment: .leading, spacing: 6 * scale) {
                        StatusChip(text: viewModel.chargingStatusText, tint: tint)
                        Text(viewModel.displayOptionalString(viewModel.battery.timeRemaining))
                            .font(type.body)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }

            // Power — outer card only, shared InlineMetric
            MaterialCard {
                VStack(alignment: .leading, spacing: 10 * scale) {
                    sectionLabel("Power")
                    LazyVGrid(columns: powerColumns, spacing: 10 * scale) {
                        InlineMetric(
                            title: "Power",
                            value: viewModel.displaySignedWatts(viewModel.battery.watts),
                            valueColor: viewModel.signedPowerColor(viewModel.battery.watts)
                        )
                        InlineMetric(
                            title: "Current",
                            value: viewModel.displaySignedCurrent(viewModel.battery.current),
                            valueColor: viewModel.signedCurrentColor(viewModel.battery.current)
                        )
                        InlineMetric(
                            title: "Voltage",
                            value: viewModel.displayVoltage(viewModel.battery.voltage)
                        )
                        InlineMetric(
                            title: "Temp",
                            value: viewModel.displayTemperature(viewModel.battery.temperatureCelsius),
                            valueColor: viewModel.temperatureColor(viewModel.battery.temperatureCelsius)
                        )
                    }
                }
            }

            MaterialCard {
                VStack(alignment: .leading, spacing: 8 * scale) {
                    sectionLabel("Health")
                    HStack {
                        Text(viewModel.displayHealth(viewModel.battery.health))
                            .font(type.heroMetric)
                            .foregroundStyle(PopoverThemeStyle.healthColor(viewModel.battery.health))
                        Spacer()
                        Text("\(viewModel.display(viewModel.battery.cycleCount)) cycles")
                            .font(type.caption)
                            .foregroundStyle(.secondary)
                    }
                    HealthBar(health: viewModel.battery.health, height: 7 * scale)
                    InfoRow(
                        label: "Max capacity",
                        value: ThemeContentHelpers.capacityText(viewModel.battery.maxCapacity)
                    )
                }
            }

            MaterialCard {
                VStack(alignment: .leading, spacing: 6 * scale) {
                    sectionLabel("Adapter")
                    if viewModel.charger.connected {
                        InfoRow(label: "Connected", value: "Yes")
                        if let detail = ThemeContentHelpers.adapterDetail(viewModel: viewModel) {
                            InfoRow(label: "Adapter", value: detail)
                        }
                    } else {
                        InfoRow(label: "Connected", value: "Unplugged")
                    }
                }
            }

            PopoverFooter()
        }
        .padding(12 * scale)
        .frame(width: profile.baseWidth * scale)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(type.caption)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.4)
    }
}
