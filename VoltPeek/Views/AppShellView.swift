import SwiftUI

private struct AppScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

extension EnvironmentValues {
    var appScale: CGFloat {
        get { self[AppScaleKey.self] }
        set { self[AppScaleKey.self] = newValue }
    }
}

/// Full app window opened from the menu-bar Settings action.
struct AppShellView: View {
    @Bindable var viewModel: BatteryViewModel
    @State private var selection: AppSection = .dashboard
    @State private var hoveredSection: AppSection?

    private var appScale: CGFloat {
        CGFloat(viewModel.settingsManager.appScalePercent) / 100
    }

    private var chromeScale: CGFloat {
        min(appScale, 1.5)
    }

    var body: some View {
        GeometryReader { geometry in
            appContent
                .frame(width: geometry.size.width, height: geometry.size.height)
                .environment(\.appScale, appScale)
        }
        .frame(minWidth: 700, idealWidth: 820, minHeight: 520, idealHeight: 600)
        .background(InitialWindowConfigurator())
    }

    private var appContent: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4 * chromeScale) {
                Text("VoltPeek")
                    .font(.system(size: 22 * chromeScale, weight: .bold))
                    .padding(.horizontal, 10 * chromeScale)
                    .padding(.bottom, 14 * chromeScale)

                ForEach(AppSection.allCases) { section in
                    Button {
                        selection = section
                    } label: {
                        Label(section.title, systemImage: section.systemImage)
                            .font(.system(
                                size: 13 * chromeScale,
                                weight: selection == section ? .semibold : .regular
                            ))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10 * chromeScale)
                            .padding(.vertical, 10 * chromeScale)
                            .background(
                                RoundedRectangle(cornerRadius: 7 * chromeScale, style: .continuous)
                                    .fill(
                                        selection == section
                                            ? Color.accentColor.opacity(0.26)
                                            : hoveredSection == section
                                                ? AppPalette.raisedSurface
                                                : Color.clear
                                    )
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(SidebarButtonStyle())
                    .frame(maxWidth: .infinity)
                    .onHover { isHovered in
                        hoveredSection = isHovered ? section : nil
                    }
                    .animation(.easeOut(duration: 0.12), value: hoveredSection)
                }

                Spacer(minLength: 0)
            }
            .padding(12 * chromeScale)
            .frame(width: 180 * chromeScale)
            .background(AppPalette.sidebar)

            Divider()

            VStack(spacing: 0) {
                HStack {
                    Text(selection.title)
                        .font(.system(size: 13 * chromeScale, weight: .semibold))
                    Spacer()
                    if selection == .dashboard {
                        if chromeScale == 1 {
                            Text("Zoom")
                                .font(.system(size: 13 * chromeScale))
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            viewModel.settingsManager.appScalePercent -= 25
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 11 * chromeScale, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(chromeScale == 1 ? .small : .large)
                        .disabled(viewModel.settingsManager.appScalePercent <= 100)
                        .accessibilityLabel("Zoom out")
                        .help("Zoom out (⌘−)")

                        Text("\(viewModel.settingsManager.appScalePercent)%")
                            .font(.system(size: 13 * chromeScale).monospacedDigit())
                            .frame(minWidth: 48 * chromeScale)

                        Button {
                            viewModel.settingsManager.appScalePercent += 25
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 11 * chromeScale, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(chromeScale == 1 ? .small : .large)
                        .disabled(viewModel.settingsManager.appScalePercent >= 300)
                        .accessibilityLabel("Zoom in")
                        .help("Zoom in (⌘+)")

                        Divider()
                            .frame(height: 20 * chromeScale)
                        Button {
                            viewModel.refreshNow()
                        } label: {
                            if chromeScale == 1 {
                                Label("Refresh", systemImage: "arrow.clockwise")
                                    .font(.system(size: 13 * chromeScale))
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 13 * chromeScale))
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(chromeScale == 1 ? .regular : .large)
                        .help("Refresh battery and adapter data")
                    }
                }
                .padding(.horizontal, 20 * chromeScale)
                .frame(height: 52 * chromeScale)
                .background(AppPalette.toolbar)

                Divider()

                detail(for: selection)
                    .id(selection)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppPalette.canvas)
        }
        .background(AppPalette.canvas)
    }

    @ViewBuilder
    private func detail(for section: AppSection) -> some View {
        switch section {
        case .dashboard:
            DashboardView(viewModel: viewModel)
        case .general:
            SettingsView(settingsManager: viewModel.settingsManager)
        case .powerGraph:
            GraphSettingsView(viewModel: viewModel)
        case .diagnostics:
            DiagnosticsView()
        case .about:
            AboutView()
        }
    }
}

private struct SidebarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.78 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

private enum AppSection: String, CaseIterable, Identifiable {
    case dashboard
    case general
    case powerGraph
    case diagnostics
    case about

    var id: Self { self }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .general: return "General"
        case .powerGraph: return "Power Graph"
        case .diagnostics: return "Diagnostics"
        case .about: return "About"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "battery.100"
        case .general: return "gearshape"
        case .powerGraph: return "chart.xyaxis.line"
        case .diagnostics: return "stethoscope"
        case .about: return "info.circle"
        }
    }
}
