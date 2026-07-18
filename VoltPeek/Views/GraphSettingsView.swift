import SwiftUI

/// Settings tab: last-1-minute signed wattage chart.
struct GraphSettingsView: View {
    @Bindable var viewModel: BatteryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Power Graph")
                .font(.title2.bold())
            Text("Live signed wattage for the last minute. Positive while charging into the battery, negative while discharging.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            WattageSparklineView(
                samples: viewModel.wattageHistory,
                latestWatts: viewModel.battery.watts,
                displayWatts: viewModel.displaySignedWatts,
                chartHeight: 160
            )

            HStack {
                Label(viewModel.chargingStatusText, systemImage: "bolt.fill")
                Spacer()
                Text(viewModel.displayPercent(viewModel.battery.percentage))
                    .monospacedDigit()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .themeEnvironment(
            theme: viewModel.settingsManager.popoverTheme,
            fontSize: viewModel.settingsManager.fontSize,
            uiScale: .standard,
            accessibility: viewModel.settingsManager.accessibility
        )
    }
}
