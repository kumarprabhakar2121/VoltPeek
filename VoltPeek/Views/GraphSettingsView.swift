import SwiftUI

/// Settings tab: last-1-minute signed wattage chart.
struct GraphSettingsView: View {
    @Bindable var viewModel: BatteryViewModel
    @Environment(\.appScale) private var scale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16 * scale) {
                Text("Power Graph")
                    .font(.system(size: 22 * scale, weight: .bold))
                Text("Live signed wattage for the last minute. Positive while charging into the battery, negative while discharging.")
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                WattageSparklineView(
                    samples: viewModel.wattageHistory,
                    latestWatts: viewModel.battery.watts,
                    displayWatts: viewModel.displaySignedWatts,
                    chartHeight: 160 * scale
                )

                HStack {
                    Label(viewModel.chargingStatusText, systemImage: "bolt.fill")
                    Spacer()
                    Text(viewModel.displayPercent(viewModel.battery.percentage))
                        .monospacedDigit()
                }
                .font(.system(size: 12 * scale))
                .foregroundStyle(.secondary)
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
}
