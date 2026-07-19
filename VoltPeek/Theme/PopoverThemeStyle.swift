import SwiftUI

/// Shared colors and surface helpers for popover themes.
enum PopoverThemeStyle {
    static let materialAccent = Color(red: 0.043, green: 0.561, blue: 0.416)
    static let chargingAccent = Color.green
    static let dischargingAccent = Color.secondary

    static func statusColor(isCharging: Bool, isOnACPower: Bool) -> Color {
        if isCharging { return chargingAccent }
        if isOnACPower { return materialAccent }
        return dischargingAccent
    }
}

/// Animated circular battery percentage ring.
struct BatteryRing: View {
    let percentage: Int
    let tint: Color
    var lineWidth: CGFloat = 8
    var size: CGFloat = 72
    @Environment(\.themeAccessibility) private var a11y

    private var progress: Double {
        min(max(Double(percentage) / 100.0, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(a11y.increaseContrast ? 0.35 : 0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.45), value: percentage)

            Text("\(percentage)%")
                .font(.system(size: size * 0.26, weight: a11y.boldText ? .bold : .semibold, design: .rounded))
                .monospacedDigit()
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Battery \(percentage) percent")
    }
}

/// Compact status pill.
struct StatusChip: View {
    let text: String
    let tint: Color
    @Environment(\.themeTypography) private var type
    @Environment(\.themeAccessibility) private var a11y

    var body: some View {
        HStack(spacing: 4) {
            if a11y.differentiateWithoutColor {
                Image(systemName: iconName)
                    .font(type.caption2)
                    .fontWeight(.bold)
            }
            Text(text)
                .font(type.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(tint.opacity(a11y.increaseContrast ? 0.28 : 0.18)))
        .foregroundStyle(tint)
        .animation(.easeInOut(duration: 0.3), value: text)
    }

    private var iconName: String {
        switch text {
        case "Charging": return "bolt.fill"
        case "On AC Power": return "powerplug.fill"
        default: return "battery.100"
        }
    }
}

/// Elevated filled card (Material).
struct MaterialCard<Content: View>: View {
    @Environment(\.themeScale) private var scale
    @Environment(\.themeProfile) private var profile
    @Environment(\.themeAccessibility) private var a11y
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(12 * scale)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: profile.cornerRadius * scale, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(
                        color: a11y.reduceTransparency ? .clear : .black.opacity(a11y.increaseContrast ? 0.16 : 0.08),
                        radius: a11y.reduceTransparency ? 0 : 3 * scale,
                        y: a11y.reduceTransparency ? 0 : 1
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: profile.cornerRadius * scale, style: .continuous)
                            .strokeBorder(
                                Color.primary.opacity(a11y.increaseContrast ? 0.35 : 0.08),
                                lineWidth: a11y.borderWidth
                            )
                    )
            )
    }
}

/// Frosted or solid panel (Liquid Glass / reduce transparency).
struct GlassPanel<Content: View>: View {
    @Environment(\.themeScale) private var scale
    @Environment(\.themeProfile) private var profile
    @Environment(\.themeAccessibility) private var a11y
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(12 * scale)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                let shape = RoundedRectangle(cornerRadius: profile.cornerRadius * scale, style: .continuous)
                Group {
                    if a11y.reduceTransparency {
                        shape.fill(Color(nsColor: .controlBackgroundColor))
                    } else {
                        shape.fill(.ultraThinMaterial)
                    }
                }
                .overlay(
                    shape.strokeBorder(.primary.opacity(a11y.borderOpacity), lineWidth: a11y.borderWidth)
                )
            }
    }
}
