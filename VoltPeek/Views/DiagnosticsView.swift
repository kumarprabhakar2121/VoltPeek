import AppKit
import SwiftUI

/// Settings tab: local crash/log report users can copy or email to support.
struct DiagnosticsView: View {
    @State private var reportText = ""
    @State private var hasCrash = false
    @State private var didCopy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Diagnostics")
                .font(.title2.bold())

            Text("Logs stay on this Mac. Nothing is uploaded. If VoltPeek crashes or misbehaves, copy the report and email it to \(AppDiagnostics.supportEmail).")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if hasCrash {
                Label("A crash was recorded on a previous launch.", systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }

            ScrollView {
                Text(reportText.isEmpty ? "Loading…" : reportText)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack(spacing: 10) {
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
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear(perform: refresh)
        .onDisappear { didCopy = false }
    }

    private func refresh() {
        reportText = AppDiagnostics.shared.supportReport()
        hasCrash = AppDiagnostics.shared.hasCapturedCrash
    }
}
