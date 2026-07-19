import SwiftUI
import AppKit

@main
struct VoltPeekApp: App {
    @State private var viewModel = BatteryViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuView(viewModel: viewModel)
        } label: {
            MenuBarLabelView(viewModel: viewModel)
                .id("\(viewModel.menuBarEpoch)|\(viewModel.settingsManager.accessibility.fingerprint)|\(viewModel.settingsManager.menuBarStyle.rawValue)|\(viewModel.settingsManager.menuBarBatteryAppearance.rawValue)")
                .task {
                    viewModel.start()
                }
        }
        .menuBarExtraStyle(.window)

        Settings {
            TabView {
                SettingsView(settingsManager: viewModel.settingsManager)
                    .tabItem {
                        Label("General", systemImage: "gearshape")
                    }
                GraphSettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("Power Graph", systemImage: "chart.xyaxis.line")
                    }
                AboutView()
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
            }
            .frame(width: 560, height: 620)
        }
    }
}

/// Isolated label view so MenuBarExtra observes `@Observable` updates reliably.
private struct MenuBarLabelView: View {
    @Bindable var viewModel: BatteryViewModel

    private var a11y: AccessibilityPreferences {
        viewModel.settingsManager.accessibility
    }

    private var batteryAppearance: MenuBarBatteryAppearance {
        viewModel.settingsManager.menuBarBatteryAppearance
    }

    var body: some View {
        let style = viewModel.settingsManager.menuBarStyle
        let pct = viewModel.battery.percentage
        let charging = viewModel.battery.isCharging
        let watts = viewModel.menuBarWattsText

        Group {
            switch style {
            case .battery:
                HStack(spacing: 4) {
                    Text("\(pct)%")
                        .monospacedDigit()
                        .fontWeight(a11y.boldText ? .bold : .regular)
                    SystemMenuBarBatteryIcon(
                        percentage: pct,
                        isCharging: charging,
                        accessibility: a11y,
                        appearance: batteryAppearance
                    )
                }
            case .watts:
                // Single composite — MenuBarExtra truncates multi-view HStacks.
                Image(nsImage: SystemMenuBarBatteryIcon.makeWattsLabelImage(
                    wattsText: watts,
                    accessibility: a11y,
                    appearance: batteryAppearance
                ))
                .renderingMode(.original)
            case .both:
                // Single composite: bolt · watts · · · percent · battery.
                Image(nsImage: SystemMenuBarBatteryIcon.makeBothLabelImage(
                    wattsText: watts,
                    percentage: pct,
                    isCharging: charging,
                    accessibility: a11y,
                    appearance: batteryAppearance
                ))
                .renderingMode(.original)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .fixedSize()
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private var accessibilityLabel: String {
        let pct = viewModel.battery.percentage
        if let watts = viewModel.battery.watts {
            return String(format: "Battery %d percent, %.0f watts", pct, watts)
        }
        return "Battery \(pct) percent"
    }
}
