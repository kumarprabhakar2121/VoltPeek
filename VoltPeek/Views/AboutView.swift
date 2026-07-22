import SwiftUI

/// Version, support contact, and short product blurb.
struct AboutView: View {
    private let supportEmail = "hello@voltpeek.app"
    private let developerName = "Prabhakar Kumar"
    private let githubProfileURL = URL(string: "https://github.com/kumarprabhakar2121")!
    private let githubRepoURL = URL(string: "https://github.com/kumarprabhakar2121/VoltPeek")!
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
                Text("A native Mac battery utility with a responsive dashboard, menu-bar telemetry, power history, and charging alerts.")
                    .fixedSize(horizontal: false, vertical: true)

                Text("VoltPeek reads battery data locally via IOKit. It does not collect telemetry or require an account. Diagnostics keep today's activity log and the latest crash marker on this Mac unless you clear them.")
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 6 * scale) {
                    Text("Developer")
                        .font(.system(size: 12 * scale, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(developerName)
                        .font(.system(size: 14 * scale, weight: .semibold))
                    Link("GitHub Profile", destination: githubProfileURL)
                    Link("VoltPeek Repository", destination: githubRepoURL)
                }
                .font(.system(size: 13 * scale))
                .padding(.top, 4 * scale)

                Link("Support: \(supportEmail)", destination: URL(string: "mailto:\(supportEmail)")!)
                    .font(.system(size: 13 * scale))
            }
            .font(.system(size: 13 * scale))
            .padding(24 * scale)
            .frame(maxWidth: 1080 * scale, alignment: .topLeading)
            .background(
                AppPalette.surface,
                in: RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                    .strokeBorder(AppPalette.border)
            )
            .padding(22 * scale)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }
}
