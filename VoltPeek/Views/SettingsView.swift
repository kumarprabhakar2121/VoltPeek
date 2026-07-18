import SwiftUI

/// Preferences: menu bar, look, behavior, accessibility — curated for personalization.
struct SettingsView: View {
    @Bindable var settingsManager: SettingsManager
    @State private var confirmReset = false

    private let menuBarColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        Form {
            Section {
                LazyVGrid(columns: menuBarColumns, spacing: 10) {
                    ForEach(MenuBarStyle.allCases) { style in
                        Button {
                            settingsManager.menuBarStyle = style
                        } label: {
                            menuBarCell(for: style)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Menu Bar")
            } footer: {
                Text("To visually replace macOS Battery, turn it off in System Settings → Control Center → Battery → Show in Menu Bar.")
            }

            if settingsManager.menuBarStyle == .text {
                Section("Text Options") {
                    Toggle("Show Watts in Menu Bar", isOn: $settingsManager.showWattsInMenuBar)
                    Toggle("Show Battery Percentage in Menu Bar", isOn: $settingsManager.showPercentageInMenuBar)
                }
            }

            Section {
                ForEach(PopoverTheme.allCases) { theme in
                    Button {
                        settingsManager.popoverTheme = theme
                    } label: {
                        HStack(spacing: 12) {
                            themeGlyph(for: theme)
                                .frame(width: 44, height: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(theme.title)
                                    .foregroundStyle(.primary)
                                Text(theme.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if settingsManager.popoverTheme == theme {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Picker("Display Size", selection: Binding(
                    get: { settingsManager.displaySize },
                    set: { settingsManager.displaySize = $0 }
                )) {
                    ForEach(DisplaySizePreference.allCases) { size in
                        Text(size.title).tag(size)
                    }
                }
            } header: {
                Text("Look")
            } footer: {
                Text("Theme changes the popover layout. Display Size scales type and spacing together.")
            }

            Section("Behavior") {
                Picker("Refresh Interval", selection: $settingsManager.refreshIntervalSeconds) {
                    ForEach(AppSettings.refreshIntervalOptions, id: \.self) { seconds in
                        Text(intervalLabel(seconds)).tag(seconds)
                    }
                }
                Toggle("Launch at Login", isOn: $settingsManager.launchAtLogin)
            }

            Section {
                Toggle("Increase Contrast", isOn: $settingsManager.increaseContrast)
                Toggle("Bold Text", isOn: $settingsManager.boldText)
                Toggle("Reduce Transparency", isOn: $settingsManager.reduceTransparency)
                Toggle("Differentiate Without Color Alone", isOn: $settingsManager.differentiateWithoutColor)
            } header: {
                Text("Accessibility")
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
        .frame(width: 540, height: 640)
        .padding()
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

    private func menuBarCell(for style: MenuBarStyle) -> some View {
        let selected = settingsManager.menuBarStyle == style
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                menuBarPreview(for: style)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                        .imageScale(.small)
                }
            }
            Text(style.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(style.subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    selected ? Color.accentColor.opacity(0.85) : Color.primary.opacity(0.08),
                    lineWidth: selected ? 2 : 1
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
        switch style {
        case .text:
            Text("⚡ +42W")
                .font(.caption.monospacedDigit())
        case .battery:
            Image(systemName: "battery.75percent")
        case .batteryPercent:
            HStack(spacing: 2) {
                Image(systemName: "battery.75percent")
                Text("75%")
                    .font(.caption.monospacedDigit())
            }
        case .bolt:
            Image(systemName: "bolt.fill")
        case .boltWatts:
            HStack(spacing: 2) {
                Image(systemName: "bolt.fill")
                Text("+42W")
                    .font(.caption.monospacedDigit())
            }
        case .batteryBolt:
            HStack(spacing: 2) {
                Image(systemName: "battery.100percent.bolt")
                Text("100%")
                    .font(.caption.monospacedDigit())
            }
        }
    }
}
