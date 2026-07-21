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
        .themeEnvironment(
            theme: viewModel.settingsManager.popoverTheme,
            fontSize: viewModel.settingsManager.fontSize,
            uiScale: viewModel.settingsManager.uiScale,
            accessibility: viewModel.settingsManager.accessibility,
            systemDifferentiateWithoutColor: systemDifferentiateWithoutColor
        )
    }
}
