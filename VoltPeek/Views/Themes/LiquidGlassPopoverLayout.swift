import SwiftUI

/// Airy glass panels — one material plane, cool blue accent.
struct LiquidGlassPopoverLayout: View {
    @Bindable var viewModel: BatteryViewModel
    @Environment(\.themeScale) private var scale
    @Environment(\.themeProfile) private var profile
    @Environment(\.themeTypography) private var type
    @Environment(\.themeAccessibility) private var a11y

    private var tint: Color {
        PopoverThemeStyle.statusColor(
            isCharging: viewModel.battery.isCharging,
            isOnACPower: viewModel.battery.isOnACPower
        )
    }

    var body: some View {
        VStack(spacing: profile.sectionSpacing * scale) {
            // Hero: ring + watts + status + time (watts live here only)
            GlassPanel {
                HStack(spacing: 14 * scale) {
                    BatteryRing(
                        percentage: viewModel.battery.percentage,
                        tint: tint,
                        lineWidth: 7 * scale,
                        size: 80 * scale
                    )

                    VStack(alignment: .leading, spacing: 6 * scale) {
                        SignedPowerBadge(viewModel: viewModel)
                        StatusChip(text: viewModel.chargingStatusText, tint: tint)
                        Text(viewModel.displayTimeRemaining())
                            .font(type.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }

            // Power mosaic — Current / Voltage / Temp (watts live in hero)
            HStack(spacing: 8 * scale) {
                GlassChip(
                    title: "Current",
                    value: viewModel.displaySignedCurrent(viewModel.battery.current),
                    valueColor: viewModel.signedCurrentColor(viewModel.battery.current)
                )
                GlassChip(
                    title: "Voltage",
                    value: viewModel.displayVoltage(viewModel.battery.voltage)
                )
                GlassChip(
                    title: "Temp",
                    value: viewModel.displayTemperature(viewModel.battery.temperatureCelsius),
                    valueColor: viewModel.temperatureColor(viewModel.battery.temperatureCelsius)
                )
            }

            GlassPanel {
                VStack(alignment: .leading, spacing: 4 * scale) {
                    Text("Health")
                        .font(type.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.4)
                    Text(ThemeContentHelpers.passiveHealthSummary(viewModel: viewModel))
                        .font(type.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            GlassPanel {
                VStack(alignment: .leading, spacing: 4 * scale) {
                    Text("Adapter")
                        .font(type.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.4)
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
        .padding(14 * scale)
        .frame(width: profile.baseWidth * scale)
        .background {
            if !a11y.reduceTransparency {
                LinearGradient(
                    colors: [tint.opacity(0.10), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
    }
}
