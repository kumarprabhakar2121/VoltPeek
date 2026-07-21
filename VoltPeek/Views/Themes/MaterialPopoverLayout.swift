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
                        Text(viewModel.displayTimeRemaining())
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
                VStack(alignment: .leading, spacing: 4 * scale) {
                    sectionLabel("Health")
                    Text(ThemeContentHelpers.passiveHealthSummary(viewModel: viewModel))
                        .font(type.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            MaterialCard {
                VStack(alignment: .leading, spacing: 6 * scale) {
                    sectionLabel("Adapter")
                    if viewModel.charger.connected {
                        InfoRow(label: "Status", value: "Connected")
                        if let detail = ThemeContentHelpers.adapterDetail(viewModel: viewModel) {
                            InfoRow(label: "Adapter", value: detail)
                        }
                        if viewModel.charger.adapterVoltage != nil {
                            InfoRow(
                                label: "Voltage",
                                value: viewModel.displayVoltage(viewModel.charger.adapterVoltage)
                            )
                        }
                        if viewModel.charger.adapterAmperage != nil {
                            InfoRow(
                                label: "Current",
                                value: viewModel.displayCurrent(viewModel.charger.adapterAmperage)
                            )
                        }
                        if let manufacturer = ThemeContentHelpers.adapterManufacturer(viewModel: viewModel) {
                            InfoRow(label: "Manufacturer", value: manufacturer)
                        }
                    } else {
                        InfoRow(label: "Status", value: "Unplugged")
                    }
                }
            }

            PopoverFooter(viewModel: viewModel)
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
