import SwiftUI

/// Version, support contact, and short product blurb.
struct AboutView: View {
    private let supportEmail = "hello@voltpeek.app"
    @Environment(\.appScale) private var scale

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12 * scale) {
                Text("VoltPeek")
                    .font(.system(size: 22 * scale, weight: .bold))
                Text("Version \(version)")
                    .foregroundStyle(.secondary)
                Text("A lightweight menu bar app that shows live battery and charging details for your Mac.")
                    .fixedSize(horizontal: false, vertical: true)

                Text("VoltPeek reads battery data locally via IOKit. It does not collect telemetry or require an account. Optional diagnostics logs stay on this Mac until you choose to share them (Settings → Diagnostics).")
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Link("Support: \(supportEmail)", destination: URL(string: "mailto:\(supportEmail)")!)
                    .font(.system(size: 13 * scale))
            }
            .font(.system(size: 13 * scale))
            .frame(maxWidth: 1080 * scale, alignment: .topLeading)
            .padding(22 * scale)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }
}
