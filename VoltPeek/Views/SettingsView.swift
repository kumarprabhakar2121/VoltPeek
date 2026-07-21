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

    private var gridSpacing: CGFloat { 16 * layoutScale }
    private var contentMargin: CGFloat { 32 * layoutScale }
    private var textLineSpacing: CGFloat { 2 * layoutScale }

    private var menuBarColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 160 * layoutScale), spacing: gridSpacing),
            GridItem(.flexible(minimum: 160 * layoutScale), spacing: gridSpacing),
            GridItem(.flexible(minimum: 160 * layoutScale), spacing: gridSpacing),
            GridItem(.flexible(minimum: 160 * layoutScale), spacing: gridSpacing)
        ]
    }

    private var popoverColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 160 * layoutScale), spacing: gridSpacing),
            GridItem(.flexible(minimum: 160 * layoutScale), spacing: gridSpacing),
            GridItem(.flexible(minimum: 160 * layoutScale), spacing: gridSpacing)
        ]
    }

    private var twoColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 180 * layoutScale), spacing: gridSpacing),
            GridItem(.flexible(minimum: 180 * layoutScale), spacing: gridSpacing)
        ]
    }

    private var oneColumn: [GridItem] {
        [GridItem(.flexible(), spacing: gridSpacing)]
    }

    private var groupedSectionColumns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: 440 * layoutScale, maximum: 680 * layoutScale),
                spacing: gridSpacing,
                alignment: .top
            )
        ]
    }

    private let menuBarStyleOrder: [MenuBarStyle] = [
        .hidden,
        .battery,
        .watts,
        .both
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22 * layoutScale) {
                settingsSection(
                    title: "Menu Bar Item",
                    systemImage: "menubar.rectangle",
                    description: "Choose what VoltPeek shows in the macOS menu bar."
                ) {
                    ViewThatFits(in: .horizontal) {
                        menuBarStyleGrid(columns: menuBarColumns)
                        menuBarStyleGrid(columns: twoColumns)
                        menuBarStyleGrid(columns: oneColumn)
                    }

                    settingsPanel {
                        settingsRow("Colored Icons") {
                            Toggle(
                                "Use colored menu bar icons",
                                isOn: Binding(
                                    get: { settingsManager.menuBarBatteryAppearance == .colored },
                                    set: {
                                        settingsManager.menuBarBatteryAppearance = $0 ? .colored : .monochrome
                                    }
                                )
                            )
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .disabled(settingsManager.menuBarStyle == .hidden)
                            .help(
                                settingsManager.menuBarStyle == .hidden
                                    ? "Choose a visible menu bar style to enable icon colors."
                                    : "Use charge-level colors and a yellow power symbol."
                            )
                        }
                        if settingsManager.menuBarStyle == .hidden {
                            Text("Choose a visible menu bar style to enable icon colors.")
                                .font(.system(size: 12 * scale))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                settingsSection(
                    title: "Menu Bar Popover",
                    systemImage: "rectangle.portrait.on.rectangle.portrait",
                    description: "Customize the panel opened from the menu bar."
                ) {
                    ViewThatFits(in: .horizontal) {
                        popoverThemeGrid(columns: popoverColumns)
                        popoverThemeGrid(columns: twoColumns)
                        popoverThemeGrid(columns: oneColumn)
                    }

                    settingsPanel {
                        settingsRow("Popover Size") {
                            Picker("Popover Size", selection: Binding(
                                get: { settingsManager.displaySize },
                                set: { settingsManager.displaySize = $0 }
                            )) {
                                ForEach(DisplaySizePreference.allCases) { size in
                                    Text(size.title).tag(size)
                                }
                            }
                            .labelsHidden()
                            .help("Changes popover text, spacing, and width without affecting the Dashboard.")
                        }
                    }
                }

                LazyVGrid(
                    columns: groupedSectionColumns,
                    alignment: .leading,
                    spacing: gridSpacing
                ) {
                    settingsSection(
                        title: "Behavior",
                        systemImage: "gearshape",
                        description: "Control updates and startup behavior."
                    ) {
                        settingsPanel {
                            settingsRow("Refresh Interval") {
                                Picker("Refresh Interval", selection: $settingsManager.refreshIntervalSeconds) {
                                    ForEach(AppSettings.refreshIntervalOptions, id: \.self) { seconds in
                                        Text(intervalLabel(seconds)).tag(seconds)
                                    }
                                }
                                .labelsHidden()
                            }
                            Divider()
                            settingsRow("Launch at Login") {
                                Toggle("Launch at Login", isOn: $settingsManager.launchAtLogin)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                            }
                        }
                        }

                    settingsSection(
                        title: "Accessibility",
                        systemImage: "accessibility",
                        description: "Improve readability throughout VoltPeek."
                    ) {
                        settingsPanel {
                            settingsRow("Increase Contrast") {
                                Toggle("Increase Contrast", isOn: $settingsManager.increaseContrast)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                            }
                            Divider()
                            settingsRow("Bold Text") {
                                Toggle("Bold Text", isOn: $settingsManager.boldText)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                            }
                            Divider()
                            settingsRow("Reduce Transparency") {
                                Toggle("Reduce Transparency", isOn: $settingsManager.reduceTransparency)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                            }
                            Divider()
                            settingsRow("Differentiate Without Color") {
                                Toggle(
                                    "Differentiate Without Color",
                                    isOn: $settingsManager.differentiateWithoutColor
                                )
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .help("Adds non-color indicators to communicate state.")
                            }
                        }
                    }
                }

                settingsSection(
                    title: "Reset Settings",
                    systemImage: "arrow.counterclockwise",
                    description: "Restore all preferences to their defaults."
                ) {
                    settingsRow("Menu bar, popover, zoom, behavior, and accessibility") {
                        Button("Reset All Settings…", role: .destructive) {
                            confirmReset = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .frame(maxWidth: 1360 * layoutScale)
            .padding(contentMargin)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .font(.system(size: 16 * scale))
        .lineSpacing(textLineSpacing)
        .controlSize(.large)
        .alert("Reset All Settings?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                settingsManager.resetToDefaults()
            }
        } message: {
            Text("Restore menu bar, popover, zoom, accessibility, and login settings to defaults?")
        }
    }

    private func settingsSection<Content: View>(
        title: String,
        systemImage: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 17 * layoutScale) {
            HStack(alignment: .top, spacing: 12 * layoutScale) {
                Image(systemName: systemImage)
                    .font(.system(size: 16 * scale, weight: .semibold))
                    .foregroundStyle(.tint)
                    .frame(width: 30 * layoutScale, height: 30 * layoutScale)
                    .background(
                        RoundedRectangle(cornerRadius: 8 * layoutScale, style: .continuous)
                            .fill(Color.accentColor.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 3 * layoutScale) {
                    Text(title)
                        .font(.system(size: 19 * scale, weight: .semibold))

                    Text(description)
                        .font(.system(size: 14 * scale))
                        .foregroundStyle(.secondary)
                        .lineSpacing(textLineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

            content()
        }
        .padding(22 * layoutScale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16 * layoutScale, style: .continuous)
                .fill(AppPalette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16 * layoutScale, style: .continuous)
                .strokeBorder(AppPalette.border, lineWidth: 1)
        )
    }

    private func settingsPanel<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14 * layoutScale) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func settingsRow<Control: View>(
        _ title: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(alignment: .center, spacing: 20 * layoutScale) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)

            control()
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, minHeight: 30 * layoutScale, alignment: .leading)
    }

    private func menuBarStyleGrid(columns: [GridItem]) -> some View {
        LazyVGrid(columns: columns, spacing: gridSpacing) {
            ForEach(menuBarStyleOrder) { style in
                Button {
                    settingsManager.menuBarStyle = style
                } label: {
                    PreferenceSelectionCard(
                        title: style.title,
                        subtitle: style.subtitle,
                        isSelected: settingsManager.menuBarStyle == style,
                        previewOnTrailing: true
                    ) {
                        menuBarPreview(for: style)
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func popoverThemeGrid(columns: [GridItem]) -> some View {
        LazyVGrid(columns: columns, spacing: gridSpacing) {
            ForEach(PopoverTheme.allCases) { theme in
                Button {
                    settingsManager.popoverTheme = theme
                } label: {
                    PreferenceSelectionCard(
                        title: theme.title,
                        subtitle: theme.subtitle,
                        isSelected: settingsManager.popoverTheme == theme,
                        previewOnTrailing: false
                    ) {
                        themeGlyph(for: theme)
                            .frame(width: 52 * layoutScale, height: 42 * layoutScale)
                    }
                }
                .buttonStyle(.plain)
            }
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
            HStack(spacing: 3 * layoutScale) {
                Text("75%")
                    .font(.system(size: 10 * scale).monospacedDigit())
                    .fontWeight(a11y.boldText ? .bold : .regular)
                SystemMenuBarBatteryIcon(
                    percentage: 75,
                    accessibility: a11y,
                    appearance: appearance,
                    height: 9 * layoutScale
                )
            }
        case .watts:
            Image(nsImage: SystemMenuBarBatteryIcon.makeWattsLabelImage(
                wattsText: "+42W",
                accessibility: a11y,
                appearance: appearance,
                height: 9 * layoutScale
            ))
            .renderingMode(.original)
        case .both:
            Image(nsImage: SystemMenuBarBatteryIcon.makeBothLabelImage(
                wattsText: "+42W",
                percentage: 75,
                isCharging: true,
                accessibility: a11y,
                appearance: appearance,
                height: 9 * layoutScale
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
    let previewOnTrailing: Bool
    @ViewBuilder let preview: () -> Preview
    @Environment(\.appScale) private var scale
    @State private var isHovered = false

    private var layoutScale: CGFloat {
        1 + ((scale - 1) * 0.5)
    }

    private var cornerRadius: CGFloat { 11 * layoutScale }

    var body: some View {
        Group {
            if previewOnTrailing {
                HStack(spacing: 16 * layoutScale) {
                    titleBlock(showsSelection: true)
                    Spacer(minLength: 12 * layoutScale)
                    previewBlock
                        .padding(.trailing, 6 * layoutScale)
                }
            } else {
                HStack(spacing: 16 * layoutScale) {
                    previewBlock
                    titleBlock(showsSelection: false)
                    Spacer(minLength: 0)
                    if isSelected {
                        selectionIndicator
                    }
                }
            }
        }
        .padding(.horizontal, 18 * layoutScale)
        .padding(.vertical, 16 * layoutScale)
        .frame(maxWidth: .infinity, minHeight: 82 * layoutScale, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    isSelected
                        ? Color.accentColor.opacity(0.22)
                        : isHovered
                            ? AppPalette.raisedSurface
                            : AppPalette.surface
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    isSelected ? Color.accentColor.opacity(0.90) : AppPalette.border,
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(
            color: isHovered || isSelected ? .black.opacity(0.10) : .clear,
            radius: 4 * layoutScale,
            y: layoutScale
        )
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .animation(.easeOut(duration: 0.12), value: isSelected)
        .onHover { isHovered = $0 }
    }

    private var previewBlock: some View {
        ZStack {
            preview()
        }
        .frame(width: 90 * layoutScale, height: 48 * layoutScale)
    }

    private func titleBlock(showsSelection: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5 * layoutScale) {
            HStack(spacing: 7 * layoutScale) {
                Text(title)
                    .font(.system(size: 16 * scale, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if showsSelection && isSelected {
                    selectionIndicator
                }
            }

            Text(subtitle)
                .font(.system(size: 13 * scale))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var selectionIndicator: some View {
        Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.tint)
            .font(.system(size: 17 * scale))
    }
}
