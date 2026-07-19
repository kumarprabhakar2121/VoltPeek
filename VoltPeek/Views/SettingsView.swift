import SwiftUI

/// Preferences: menu bar, look, behavior, accessibility — curated for personalization.
struct SettingsView: View {
    @Bindable var settingsManager: SettingsManager
    @State private var confirmReset = false

    private let selectionColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        Form {
            Section {
                LazyVGrid(columns: selectionColumns, spacing: 10) {
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
                .padding(.vertical, 2)
            } header: {
                Label("Menu Bar", systemImage: "menubar.rectangle")
            } footer: {
                Text("To visually replace macOS Battery, turn it off in System Settings → Control Center → Battery → Show in Menu Bar.")
            }

            if settingsManager.menuBarStyle != .watts {
                Section {
                    Picker("Battery Icon", selection: $settingsManager.menuBarBatteryAppearance) {
                        ForEach(MenuBarBatteryAppearance.allCases) { appearance in
                            Text(appearance.title).tag(appearance)
                        }
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text("Colored uses red / orange / yellow / green by charge level. Black & White matches the menu bar tint.")
                }
            }

            Section {
                LazyVGrid(columns: selectionColumns, spacing: 10) {
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
                                    .frame(width: 44, height: 36)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)

                Picker("Display Size", selection: Binding(
                    get: { settingsManager.displaySize },
                    set: { settingsManager.displaySize = $0 }
                )) {
                    ForEach(DisplaySizePreference.allCases) { size in
                        Text(size.title).tag(size)
                    }
                }
            } header: {
                Label("Look", systemImage: "paintbrush")
            } footer: {
                Text("Theme changes the popover layout. Display Size scales type and spacing together.")
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
            }

            Section {
                Toggle("Increase Contrast", isOn: $settingsManager.increaseContrast)
                Toggle("Bold Text", isOn: $settingsManager.boldText)
                Toggle("Reduce Transparency", isOn: $settingsManager.reduceTransparency)
                Toggle("Differentiate Without Color Alone", isOn: $settingsManager.differentiateWithoutColor)
            } header: {
                Label("Accessibility", systemImage: "accessibility")
            } footer: {
                Text("These are in-app overrides and combine with system accessibility settings.")
            }

            Section {
                Button("Reset All Settings…", role: .destructive) {
                    confirmReset = true
                }
            }
        }
        .formStyle(.grouped)
        .alert("Reset All Settings?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                settingsManager.resetToDefaults()
            }
        } message: {
            Text("Restore theme, menu bar, display size, accessibility, and login item to defaults?")
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
        let shape = RoundedRectangle(cornerRadius: theme == .compact ? 2 : 8, style: .continuous)
        ZStack {
            switch theme {
            case .compact:
                shape
                    .strokeBorder(Color.secondary.opacity(0.45), lineWidth: 1)
                    .background(shape.fill(Color(nsColor: .controlBackgroundColor)))
                VStack(spacing: 3) {
                    Capsule().fill(Color.secondary.opacity(0.55)).frame(width: 22, height: 2)
                    Capsule().fill(Color.secondary.opacity(0.35)).frame(width: 18, height: 2)
                    Capsule().fill(Color.secondary.opacity(0.25)).frame(width: 14, height: 2)
                }
            case .material:
                shape
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                    .overlay(shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.teal.opacity(0.55))
                        .frame(width: 20, height: 6)
                    HStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.secondary.opacity(0.25)).frame(width: 8, height: 8)
                        RoundedRectangle(cornerRadius: 2).fill(Color.secondary.opacity(0.25)).frame(width: 8, height: 8)
                    }
                }
            case .liquidGlass:
                shape
                    .fill(.ultraThinMaterial)
                    .overlay(shape.strokeBorder(Color.cyan.opacity(0.35), lineWidth: 1))
                Circle()
                    .strokeBorder(Color.cyan.opacity(0.7), lineWidth: 2)
                    .frame(width: 16, height: 16)
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
                    .font(.caption.monospacedDigit())
                    .fontWeight(a11y.boldText ? .bold : .regular)
                SystemMenuBarBatteryIcon(
                    percentage: 75,
                    accessibility: a11y,
                    appearance: appearance,
                    height: 11
                )
            }
        case .watts:
            Image(nsImage: SystemMenuBarBatteryIcon.makeWattsLabelImage(
                wattsText: "+42W",
                accessibility: a11y,
                appearance: appearance,
                height: 11
            ))
            .renderingMode(.original)
        case .both:
            Image(nsImage: SystemMenuBarBatteryIcon.makeBothLabelImage(
                wattsText: "+42W",
                percentage: 75,
                isCharging: true,
                accessibility: a11y,
                appearance: appearance,
                height: 11
            ))
            .renderingMode(.original)
        }
    }
}

/// Shared selection card for visual preference grids (menu bar style, theme).
private struct PreferenceSelectionCard<Preview: View>: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    @ViewBuilder let preview: () -> Preview

    private let cornerRadius: CGFloat = 11

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                preview()
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                        .imageScale(.small)
                }
            }
            .frame(minHeight: 28, alignment: .topLeading)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
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
