import SwiftUI

/// Simple label/value row used across themes.
struct InfoRow: View {
    @Environment(\.themeTypography) private var type
    @Environment(\.themeAccessibility) private var a11y

    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(type.body)
                .foregroundStyle(.secondary.opacity(a11y.secondaryOpacity))
                .fixedSize(horizontal: true, vertical: false)
            Text(value)
                .font(type.body)
                .fontWeight(a11y.boldText ? .bold : .semibold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
