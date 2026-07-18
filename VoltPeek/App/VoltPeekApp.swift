import SwiftUI
import AppKit

@main
struct VoltPeekApp: App {
    @State private var viewModel = BatteryViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuView(viewModel: viewModel)
        } label: {
            menuBarLabel
                .onAppear {
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

    @ViewBuilder
    private var menuBarLabel: some View {
        let style = viewModel.settingsManager.menuBarStyle
        let symbol = viewModel.menuBarSymbolName
        let text = viewModel.menuBarAccessoryText

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
}
