import SwiftUI
import AppKit

/// Shared Settings / Refresh / Quit footer.
struct PopoverFooter: View {
    @Bindable var viewModel: BatteryViewModel
    @Environment(\.openSettings) private var openSettings
    @Environment(\.themeTypography) private var type
    @Environment(\.themeScale) private var scale
    @Environment(\.themeAccessibility) private var a11y

    var body: some View {
        VStack(spacing: 8 * scale) {
            Rectangle()
                .fill(Color.primary.opacity(a11y.increaseContrast ? 0.28 : 0.1))
                .frame(height: 1)

            HStack {
                Button {
                    SettingsWindowPresenter.open {
                        openSettings()
                    }
                } label: {
                    Label("Settings…", systemImage: "gear")
                }
                .buttonStyle(PopoverFooterButtonStyle(font: type.caption))

                Spacer()

                Button {
                    viewModel.refreshNow()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(PopoverFooterButtonStyle(font: type.caption))
                .help("Re-read battery data and clear the power graph")

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(PopoverFooterButtonStyle(font: type.caption))
            }
        }
    }
}

/// Pointing-hand cursor + hover highlight so footer actions feel clickable.
private struct PopoverFooterButtonStyle: ButtonStyle {
    let font: Font
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundStyle(isHovered || configuration.isPressed ? Color.primary : Color.secondary)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1)
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

/// Presents the SwiftUI `Settings` scene from a menu bar (`LSUIElement`) app.
@MainActor
enum SettingsWindowPresenter {
    private static var resignObserver: NSObjectProtocol?

    static func open(using openSettings: @escaping () -> Void) {
        if resignObserver == nil {
            resignObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                let hasVisibleWindow = NSApp.windows.contains {
                    $0.isVisible && !$0.className.contains("NSStatusBar") && $0.canBecomeKey
                }
                if !hasVisibleWindow {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        openSettings()
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

/// Colored signed power value (AccuBattery style).
struct SignedPowerBadge: View {
    let viewModel: BatteryViewModel
    @Environment(\.themeTypography) private var type
    @Environment(\.themeAccessibility) private var a11y

    var body: some View {
        HStack(spacing: 4) {
            if a11y.differentiateWithoutColor {
                Image(systemName: (viewModel.battery.watts ?? 0) >= 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .foregroundStyle(viewModel.signedPowerColor(viewModel.battery.watts))
            }
            Text(viewModel.displaySignedWatts(viewModel.battery.watts))
                .font(type.heroMetric)
                .monospacedDigit()
                .foregroundStyle(viewModel.signedPowerColor(viewModel.battery.watts))
        }
    }
}

/// Temperature with cool/warm/hot coloring.
struct TempBadge: View {
    let viewModel: BatteryViewModel
    @Environment(\.themeTypography) private var type

    var body: some View {
        Text(viewModel.displayTemperature(viewModel.battery.temperatureCelsius))
            .font(type.metric)
            .monospacedDigit()
            .foregroundStyle(viewModel.temperatureColor(viewModel.battery.temperatureCelsius))
    }
}

/// Compact horizontal metric used in Material redesign.
struct InlineMetric: View {
    @Environment(\.themeTypography) private var type
    @Environment(\.themeScale) private var scale

    let title: String
    let value: String
    var valueColor: Color = .primary
    var systemImage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2 * scale) {
            HStack(spacing: 3) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(type.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(title)
                    .font(type.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(type.metricEmphasized)
                .monospacedDigit()
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Narrow frosted chip for Liquid Glass side column.
struct GlassChip: View {
    @Environment(\.themeScale) private var scale
    @Environment(\.themeTypography) private var type
    @Environment(\.themeAccessibility) private var a11y

    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 3 * scale) {
            Text(title)
                .font(type.caption2)
                .foregroundStyle(.secondary.opacity(a11y.secondaryOpacity))
            Text(value)
                .font(type.metricEmphasized)
                .monospacedDigit()
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 10 * scale)
        .padding(.vertical, 8 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            let shape = RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
            Group {
                if a11y.reduceTransparency {
                    shape.fill(Color(nsColor: .controlBackgroundColor))
                } else {
                    shape.fill(.thinMaterial)
                }
            }
            .overlay(shape.strokeBorder(.primary.opacity(a11y.borderOpacity), lineWidth: 0.6))
        }
    }
}

/// Colored AccuBattery-style label/value row.
struct SignedMetricRow: View {
    @Environment(\.themeTypography) private var type
    @Environment(\.themeAccessibility) private var a11y

    let label: String
    let value: String
    var valueColor: Color = .primary
    var systemImage: String? = nil

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                if a11y.differentiateWithoutColor, let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(.secondary)
                }
                Text(label)
                    .foregroundStyle(.secondary.opacity(a11y.secondaryOpacity))
            }
            Spacer()
            Text(value)
                .font(type.metric)
                .monospacedDigit()
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .font(type.body)
    }
}
