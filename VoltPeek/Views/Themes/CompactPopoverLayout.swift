import SwiftUI

/// Dense typography utility — no cards, rings, or chips.
struct CompactPopoverLayout: View {
    @Bindable var viewModel: BatteryViewModel
    @Environment(\.themeScale) private var scale
    @Environment(\.themeProfile) private var profile
    @Environment(\.themeTypography) private var type
    @Environment(\.themeAccessibility) private var a11y

    var body: some View {
        VStack(alignment: .leading, spacing: profile.sectionSpacing * scale) {
            // Status hero
            VStack(alignment: .leading, spacing: 2 * scale) {
                HStack(alignment: .firstTextBaseline) {
                    Text(viewModel.displayPercent(viewModel.battery.percentage))
                        .font(type.title)
                        .monospacedDigit()
                    Spacer(minLength: 8)
                    Text(viewModel.chargingStatusText)
                        .font(type.caption)
                        .fontWeight(a11y.boldText ? .bold : .semibold)
                        .foregroundStyle(.secondary)
                }
                Text(viewModel.displayTimeRemaining())
                    .font(type.caption)
                    .foregroundStyle(.secondary.opacity(a11y.secondaryOpacity))
            }

            group("Power") {
                metricRow(
                    "Power",
                    viewModel.displaySignedWatts(viewModel.battery.watts),
                    color: viewModel.signedPowerColor(viewModel.battery.watts)
                )
                metricRow(
                    "Current",
                    viewModel.displaySignedCurrent(viewModel.battery.current),
                    color: viewModel.signedCurrentColor(viewModel.battery.current)
                )
                metricRow("Voltage", viewModel.displayVoltage(viewModel.battery.voltage))
                metricRow(
                    "Temp",
                    viewModel.displayTemperature(viewModel.battery.temperatureCelsius),
                    color: viewModel.temperatureColor(viewModel.battery.temperatureCelsius)
                )
            }

            group("Health") {
                Text(ThemeContentHelpers.passiveHealthSummary(viewModel: viewModel))
                    .font(type.caption)
                    .foregroundStyle(.secondary.opacity(a11y.secondaryOpacity))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            group("Adapter") {
                if viewModel.charger.connected {
                    metricRow("Status", "Connected")
                    if let detail = ThemeContentHelpers.adapterDetail(viewModel: viewModel) {
                        metricRow("Adapter", detail)
                    }
                    if viewModel.charger.adapterVoltage != nil {
                        metricRow("Voltage", viewModel.displayVoltage(viewModel.charger.adapterVoltage))
                    }
                    if viewModel.charger.adapterAmperage != nil {
                        metricRow("Current", viewModel.displayCurrent(viewModel.charger.adapterAmperage))
                    }
                    if let manufacturer = ThemeContentHelpers.adapterManufacturer(viewModel: viewModel) {
                        metricRow("Manufacturer", manufacturer)
                    }
                } else {
                    metricRow("Status", "Unplugged")
                }
            }

            PopoverFooter(viewModel: viewModel)
        }
        .padding(12 * scale)
        .frame(width: profile.baseWidth * scale)
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 3 * scale) {
            Text(title)
                .font(type.caption)
                .fontWeight(a11y.boldText ? .bold : .semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.4)
            content()
        }
    }

    private func metricRow(_ label: String, _ value: String, color: Color = .primary) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(type.body)
                .foregroundStyle(.secondary.opacity(a11y.secondaryOpacity))
            Spacer(minLength: 8)
            Text(value)
                .font(type.body)
                .fontWeight(a11y.boldText ? .bold : .semibold)
                .monospacedDigit()
                .foregroundStyle(color)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 1 * scale)
    }
}
