import AppKit
import SwiftUI

/// Settings tab: local activity/crash report users can explicitly share.
struct DiagnosticsView: View {
    @State private var reportText = ""
    @State private var hasCrash = false
    @State private var didCopy = false
    @Environment(\.appScale) private var scale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14 * scale) {
            Text("Diagnostics")
                .font(.system(size: 22 * scale, weight: .bold))

            Text("Activity logs and crash stack traces stay on this Mac until you choose to report a problem.")
                .font(.system(size: 13 * scale))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if hasCrash {
                Label("A crash was recorded on a previous launch.", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(.orange)
            }

            ScrollView {
                Text(reportText.isEmpty ? "Loading…" : reportText)
                    .font(.system(size: 11 * scale, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10 * scale)
            }
            .frame(minHeight: 240 * scale, maxHeight: 400 * scale)
            .background(
                AppPalette.surface,
                in: RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                    .strokeBorder(AppPalette.border)
            )

            HStack(spacing: 10 * scale) {
                Button {
                    AppDiagnostics.shared.reportOnGitHub()
                    didCopy = true
                } label: {
                    Label("Report on GitHub", systemImage: "ladybug")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    AppDiagnostics.shared.emailSupportWithReport()
                    didCopy = true
                } label: {
                    Label("Email Report", systemImage: "envelope")
                }

                Button {
                    AppDiagnostics.shared.copySupportReportToPasteboard()
                    didCopy = true
                } label: {
                    Label(didCopy ? "Copied" : "Copy Report", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }

            HStack(spacing: 10 * scale) {
                Spacer(minLength: 0)

                Button("Reveal in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([AppDiagnostics.shared.diagnosticsDirectoryURL])
                }
                .buttonStyle(.borderless)

                Button("Clear", role: .destructive) {
                    AppDiagnostics.shared.clearLogs()
                    refresh()
                    didCopy = false
                }
                .buttonStyle(.borderless)
            }

            Text("GitHub and email open with the report already filled in. The complete report is also copied as a fallback; review it before submitting because macOS crash reports can include device metadata.")
                .font(.system(size: 11 * scale))
                .foregroundStyle(.tertiary)
            }
            .font(.system(size: 13 * scale))
            .padding(22 * scale)
            .frame(maxWidth: 1080 * scale, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .onAppear {
            AppDiagnostics.shared.log("Diagnostics screen opened")
            refresh()
        }
        .onDisappear { didCopy = false }
    }

    private func refresh() {
        reportText = AppDiagnostics.shared.supportReport()
        hasCrash = AppDiagnostics.shared.hasCapturedCrash
    }
}
