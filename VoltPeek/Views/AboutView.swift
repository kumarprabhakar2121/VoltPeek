import SwiftUI

/// Version, support contact, and short product blurb.
struct AboutView: View {
    private let supportEmail = "hello@voltpeek.app"

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("VoltPeek")
                .font(.title2.bold())
            Text("Version \(version)")
                .foregroundStyle(.secondary)
            Text("A lightweight menu bar app that shows live battery and charging details for your Mac.")
                .fixedSize(horizontal: false, vertical: true)

            Text("VoltPeek reads battery data locally via IOKit. It does not collect telemetry or require an account.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Link("Support: \(supportEmail)", destination: URL(string: "mailto:\(supportEmail)")!)
                .font(.callout)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(22)
    }
}
