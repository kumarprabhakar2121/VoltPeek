import SwiftUI
import AppKit

enum AppWindow {
    static let main = "main"
}

@main
struct VoltPeekApp: App {
    @State private var viewModel = BatteryViewModel()

    init() {
        AppDiagnostics.shared.install()
    }

    var body: some Scene {
        Window("VoltPeek", id: AppWindow.main) {
            AppShellView(viewModel: viewModel)
        }
        .defaultSize(width: 860, height: 620)
        .windowResizability(.contentMinSize)
        .commands {
            VoltPeekCommands(settingsManager: viewModel.settingsManager)
        }

        MenuBarExtra(isInserted: Binding(
            get: { viewModel.settingsManager.menuBarStyle != .hidden },
            set: { isInserted in
                if !isInserted {
                    viewModel.settingsManager.menuBarStyle = .hidden
                } else if viewModel.settingsManager.menuBarStyle == .hidden {
                    viewModel.settingsManager.menuBarStyle = .battery
                }
            }
        )) {
            MenuView(viewModel: viewModel)
        } label: {
            MenuBarLabelView(viewModel: viewModel)
                .id("\(viewModel.menuBarEpoch)|\(viewModel.settingsManager.accessibility.fingerprint)|\(viewModel.settingsManager.menuBarStyle.rawValue)|\(viewModel.settingsManager.menuBarBatteryAppearance.rawValue)")
                .task {
                    viewModel.start()
                }
        }
        .menuBarExtraStyle(.window)
    }
}

private struct VoltPeekCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    let settingsManager: SettingsManager

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Show VoltPeek") {
                openWindow(id: AppWindow.main)
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut(",", modifiers: .command)
        }

        CommandGroup(after: .toolbar) {
            Button("Zoom In") {
                settingsManager.appScalePercent += 25
            }
            .keyboardShortcut("+", modifiers: .command)
            .disabled(settingsManager.appScalePercent >= 300)

            Button("Zoom Out") {
                settingsManager.appScalePercent -= 25
            }
            .keyboardShortcut("-", modifiers: .command)
            .disabled(settingsManager.appScalePercent <= 100)
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
            case .hidden:
                EmptyView()
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
