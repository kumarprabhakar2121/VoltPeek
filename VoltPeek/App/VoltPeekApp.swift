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
                .id(viewModel.menuBarEpoch)
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
            .frame(width: 500, height: 580)
        }
    }
}

/// Isolated label view so MenuBarExtra observes `@Observable` updates reliably.
private struct MenuBarLabelView: View {
    @Bindable var viewModel: BatteryViewModel

    var body: some View {
        let style = viewModel.settingsManager.menuBarStyle
        let symbol = viewModel.menuBarSymbolName
        let text = viewModel.menuBarAccessoryText

        Group {
            switch style {
            case .text:
                Text(text)
            case .battery, .bolt:
                if let symbol {
                    Image(systemName: symbol)
                        .symbolRenderingMode(.hierarchical)
                }
            case .batteryPercent, .boltWatts, .batteryBolt:
                HStack(spacing: 3) {
                    if let symbol {
                        Image(systemName: symbol)
                            .symbolRenderingMode(.hierarchical)
                    }
                    if !text.isEmpty {
                        Text(text)
                            .monospacedDigit()
                    }
                }
            }
        }
        // Keep observation tied to live battery fields (not only derived strings).
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
