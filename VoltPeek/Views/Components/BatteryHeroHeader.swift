import SwiftUI
import AppKit

/// Shared Settings / Refresh / Quit footer.
struct PopoverFooter: View {
    @Bindable var viewModel: BatteryViewModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.themeTypography) private var type
    @Environment(\.themeScale) private var scale
    @Environment(\.themeAccessibility) private var a11y

    var body: some View {
        VStack(spacing: 8 * scale) {
            Rectangle()
                .fill(Color.primary.opacity(a11y.increaseContrast ? 0.28 : 0.08))
                .frame(height: 1)

            HStack {
                Button {
                    openWindow(id: AppWindow.main)
                    NSApp.activate(ignoringOtherApps: true)
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
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        configuration.isPressed
                            ? Color.primary.opacity(0.09)
                            : isHovered
                                ? Color.primary.opacity(0.055)
                                : Color.clear
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.10), value: isHovered)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
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

/// Compact horizontal metric used in Material redesign.
struct InlineMetric: View {
    @Environment(\.themeTypography) private var type
    @Environment(\.themeScale) private var scale

    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 2 * scale) {
            Text(title)
                .font(type.caption2)
                .foregroundStyle(.secondary)
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
                    shape.fill(AppPalette.surface)
                } else {
                    shape
                        .fill(.thinMaterial)
                        .overlay(shape.fill(Color.cyan.opacity(0.025)))
                }
            }
            .overlay(shape.strokeBorder(AppPalette.border.opacity(0.80), lineWidth: 0.6))
        }
    }
}
