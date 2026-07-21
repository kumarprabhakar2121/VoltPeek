import SwiftUI

/// Themed popover content shown when the menu bar icon is clicked.
struct MenuView: View {
    @Bindable var viewModel: BatteryViewModel
    @Environment(\.accessibilityDifferentiateWithoutColor) private var systemDifferentiateWithoutColor

    private var environmentFingerprint: String {
        [
            viewModel.settingsManager.popoverTheme.rawValue,
            viewModel.settingsManager.fontSize.rawValue,
            viewModel.settingsManager.uiScale.rawValue,
            viewModel.settingsManager.accessibility.fingerprint
        ].joined(separator: "|")
    }

    var body: some View {
        Group {
            switch viewModel.settingsManager.popoverTheme {
            case .compact:
                CompactPopoverLayout(viewModel: viewModel)
            case .material:
                MaterialPopoverLayout(viewModel: viewModel)
            case .liquidGlass:
                LiquidGlassPopoverLayout(viewModel: viewModel)
            }
        }
        .id(environmentFingerprint)
        .background {
            ZStack {
                AppPalette.canvas
                switch viewModel.settingsManager.popoverTheme {
                case .compact:
                    Color.primary.opacity(0.012)
                case .material:
                    Color.primary.opacity(0.012)
                case .liquidGlass:
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.04), Color.blue.opacity(0.018)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                if viewModel.battery.isCharging {
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.028),
                            Color.green.opacity(0.008),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .transition(.opacity)
                }
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.45), value: viewModel.battery.isCharging)
        }
        .themeEnvironment(
            theme: viewModel.settingsManager.popoverTheme,
            fontSize: viewModel.settingsManager.fontSize,
            uiScale: viewModel.settingsManager.uiScale,
            accessibility: viewModel.settingsManager.accessibility,
            systemDifferentiateWithoutColor: systemDifferentiateWithoutColor
        )
    }
}
