import AppKit
import SwiftUI

/// Settings tab: local crash/log report users can copy or email to support.
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

            Text("Logs stay on this Mac. Nothing is uploaded. If VoltPeek crashes or misbehaves, copy the report and email it to \(AppDiagnostics.supportEmail).")
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
                .quaternary.opacity(0.35),
                in: RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
            )

            HStack(spacing: 10 * scale) {
                Button {
                    AppDiagnostics.shared.copySupportReportToPasteboard()
                    didCopy = true
                } label: {
                    Label(didCopy ? "Copied" : "Copy Report", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])

                Button {
                    AppDiagnostics.shared.emailSupportWithReport()
                    didCopy = true
                } label: {
                    Label("Email Support", systemImage: "envelope")
                }

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

            Text("Tip: Email Support copies the report first — paste it into the message body.")
                .font(.system(size: 11 * scale))
                .foregroundStyle(.tertiary)
            }
            .font(.system(size: 13 * scale))
            .padding(22 * scale)
            .frame(maxWidth: 1080 * scale, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .onAppear(perform: refresh)
        .onDisappear { didCopy = false }
    }

    private func refresh() {
        reportText = AppDiagnostics.shared.supportReport()
        hasCrash = AppDiagnostics.shared.hasCapturedCrash
    }
}
