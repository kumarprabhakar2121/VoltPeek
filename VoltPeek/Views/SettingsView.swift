import SwiftUI

/// Clearly grouped preferences for the menu bar, popover, behavior, and accessibility.
struct SettingsView: View {
    @Bindable var settingsManager: SettingsManager
    @State private var confirmReset = false
    @Environment(\.appScale) private var scale

    /// Spacing grows more slowly than typography to preserve information density.
    private var layoutScale: CGFloat {
        1 + ((scale - 1) * 0.5)
    }

    private var gridSpacing: CGFloat { 10 * layoutScale }
    private var contentMargin: CGFloat { 22 * layoutScale }
    private var textLineSpacing: CGFloat { 2 * layoutScale }

    private var selectionColumns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: 180 * layoutScale, maximum: 260 * layoutScale),
                spacing: gridSpacing
            )
        ]
    }

    var body: some View {
        Form {
            Section {
                LazyVGrid(columns: selectionColumns, spacing: gridSpacing) {
                    ForEach(MenuBarStyle.allCases) { style in
                        Button {
                            settingsManager.menuBarStyle = style
                        } label: {
                            PreferenceSelectionCard(
                                title: style.title,
                                subtitle: style.subtitle,
                                isSelected: settingsManager.menuBarStyle == style
                            ) {
                                menuBarPreview(for: style)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2 * layoutScale)

                Divider()

                Toggle(
                    "Use colored menu bar icons",
                    isOn: Binding(
                        get: { settingsManager.menuBarBatteryAppearance == .colored },
                        set: {
                            settingsManager.menuBarBatteryAppearance = $0 ? .colored : .monochrome
                        }
                    )
                )
            } header: {
                Label("Menu Bar Item", systemImage: "menubar.rectangle")
            } footer: {
                Text("Choose what VoltPeek displays in the macOS menu bar. Hidden removes the item; open VoltPeek from the Dock and choose another style to restore it. Colored icons use charge-level colors and a yellow power symbol.")
            }

            Section {
                LazyVGrid(columns: selectionColumns, spacing: gridSpacing) {
                    ForEach(PopoverTheme.allCases) { theme in
                        Button {
                            settingsManager.popoverTheme = theme
                        } label: {
                            PreferenceSelectionCard(
                                title: theme.title,
                                subtitle: theme.subtitle,
                                isSelected: settingsManager.popoverTheme == theme
                            ) {
                                themeGlyph(for: theme)
                                    .frame(width: 44 * layoutScale, height: 36 * layoutScale)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2 * layoutScale)

                Picker("Popover Size", selection: Binding(
                    get: { settingsManager.displaySize },
                    set: { settingsManager.displaySize = $0 }
                )) {
                    ForEach(DisplaySizePreference.allCases) { size in
                        Text(size.title).tag(size)
                    }
                }
            } header: {
                Label("Menu Bar Popover", systemImage: "rectangle.portrait.on.rectangle.portrait")
            } footer: {
                Text("Theme changes the layout of the floating panel opened from the menu bar. Popover Size changes its text, spacing, and width. These options do not affect the Dashboard.")
            }

            Section {
                Picker("Refresh Interval", selection: $settingsManager.refreshIntervalSeconds) {
                    ForEach(AppSettings.refreshIntervalOptions, id: \.self) { seconds in
                        Text(intervalLabel(seconds)).tag(seconds)
                    }
                }
                Toggle("Launch at Login", isOn: $settingsManager.launchAtLogin)
            } header: {
                Label("Behavior", systemImage: "gearshape")
            } footer: {
                Text("Refresh Interval controls how often battery data updates everywhere. Launch at Login starts VoltPeek automatically after you sign in.")
            }

            Section {
                Toggle("Increase Contrast", isOn: $settingsManager.increaseContrast)
                Toggle("Bold Text", isOn: $settingsManager.boldText)
                Toggle("Reduce Transparency", isOn: $settingsManager.reduceTransparency)
                Toggle("Differentiate Without Color Alone", isOn: $settingsManager.differentiateWithoutColor)
            } header: {
                Label("Accessibility", systemImage: "accessibility")
            } footer: {
                Text("Applies across the standalone app and menu bar popover. These overrides work together with your macOS accessibility settings.")
            }

            Section {
                Button("Reset All Settings…", role: .destructive) {
                    confirmReset = true
                }
            } footer: {
                Text("Restores menu bar, popover, app scale, behavior, and accessibility options to their defaults.")
            }
        }
        .font(.system(size: 13 * scale))
        .lineSpacing(textLineSpacing)
        .controlSize(scale > 1 ? .large : .regular)
        .formStyle(.grouped)
        .contentMargins(.horizontal, contentMargin, for: .scrollContent)
        .contentMargins(.vertical, contentMargin, for: .scrollContent)
        .frame(maxWidth: 1080 * layoutScale)
        .frame(maxWidth: .infinity)
        .alert("Reset All Settings?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                settingsManager.resetToDefaults()
            }
        } message: {
            Text("Restore menu bar, popover, app scale, accessibility, and login settings to defaults?")
        }
    }

    private func intervalLabel(_ seconds: Double) -> String {
        if seconds < 1 {
            return String(format: "%.1f seconds", seconds)
        }
        if seconds == 1 {
            return "1 second"
        }
        if seconds.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(seconds)) seconds"
        }
        return String(format: "%.1f seconds", seconds)
    }

    @ViewBuilder
    private func themeGlyph(for theme: PopoverTheme) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: (theme == .compact ? 2 : 8) * layoutScale,
            style: .continuous
        )
        ZStack {
            switch theme {
            case .compact:
                shape
                    .strokeBorder(Color.secondary.opacity(0.45), lineWidth: 1)
                    .background(shape.fill(Color(nsColor: .controlBackgroundColor)))
                VStack(spacing: 3 * layoutScale) {
                    Capsule().fill(Color.secondary.opacity(0.55)).frame(width: 22 * layoutScale, height: 2 * layoutScale)
                    Capsule().fill(Color.secondary.opacity(0.35)).frame(width: 18 * layoutScale, height: 2 * layoutScale)
                    Capsule().fill(Color.secondary.opacity(0.25)).frame(width: 14 * layoutScale, height: 2 * layoutScale)
                }
            case .material:
                shape
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.12), radius: 2 * layoutScale, y: layoutScale)
                    .overlay(shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
                VStack(spacing: 3 * layoutScale) {
                    RoundedRectangle(cornerRadius: 2 * layoutScale)
                        .fill(Color.teal.opacity(0.55))
                        .frame(width: 20 * layoutScale, height: 6 * layoutScale)
                    HStack(spacing: 3 * layoutScale) {
                        RoundedRectangle(cornerRadius: 2 * layoutScale).fill(Color.secondary.opacity(0.25)).frame(width: 8 * layoutScale, height: 8 * layoutScale)
                        RoundedRectangle(cornerRadius: 2 * layoutScale).fill(Color.secondary.opacity(0.25)).frame(width: 8 * layoutScale, height: 8 * layoutScale)
                    }
                }
            case .liquidGlass:
                shape
                    .fill(.ultraThinMaterial)
                    .overlay(shape.strokeBorder(Color.cyan.opacity(0.35), lineWidth: 1))
                Circle()
                    .strokeBorder(Color.cyan.opacity(0.7), lineWidth: 2 * layoutScale)
                    .frame(width: 16 * layoutScale, height: 16 * layoutScale)
            }
        }
    }

    @ViewBuilder
    private func menuBarPreview(for style: MenuBarStyle) -> some View {
        let a11y = settingsManager.accessibility
        let appearance = settingsManager.menuBarBatteryAppearance

        switch style {
        case .battery:
            HStack(spacing: 3) {
                Text("75%")
                    .font(.system(size: 11 * scale).monospacedDigit())
                    .fontWeight(a11y.boldText ? .bold : .regular)
                SystemMenuBarBatteryIcon(
                    percentage: 75,
                    accessibility: a11y,
                    appearance: appearance,
                    height: 11 * layoutScale
                )
            }
        case .watts:
            Image(nsImage: SystemMenuBarBatteryIcon.makeWattsLabelImage(
                wattsText: "+42W",
                accessibility: a11y,
                appearance: appearance,
                height: 11 * layoutScale
            ))
            .renderingMode(.original)
        case .both:
            Image(nsImage: SystemMenuBarBatteryIcon.makeBothLabelImage(
                wattsText: "+42W",
                percentage: 75,
                isCharging: true,
                accessibility: a11y,
                appearance: appearance,
                height: 11 * layoutScale
            ))
            .renderingMode(.original)
        case .hidden:
            Image(systemName: "eye.slash")
                .foregroundStyle(.secondary)
        }
    }
}

/// Shared selection card for visual preference grids (menu bar style, theme).
private struct PreferenceSelectionCard<Preview: View>: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    @ViewBuilder let preview: () -> Preview
    @Environment(\.appScale) private var scale

    private var layoutScale: CGFloat {
        1 + ((scale - 1) * 0.5)
    }

    private var cornerRadius: CGFloat { 11 * layoutScale }

    var body: some View {
        VStack(alignment: .leading, spacing: 8 * layoutScale) {
            HStack(alignment: .top) {
                preview()
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                        .imageScale(.small)
                }
            }
            .frame(minHeight: 28 * layoutScale, alignment: .topLeading)

            Text(title)
                .font(.system(size: 13 * scale, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(subtitle)
                .font(.system(size: 10 * scale))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .lineSpacing(2 * layoutScale)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12 * layoutScale)
        .frame(maxWidth: .infinity, minHeight: 96 * layoutScale, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    isSelected ? Color.accentColor.opacity(0.85) : Color.primary.opacity(0.08),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
