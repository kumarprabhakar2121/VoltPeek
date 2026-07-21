import SwiftUI

struct PowerAlertPillView: View {
    let event: PowerAlertEvent
    let accessibility: AccessibilityPreferences

    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency

    private var usesSolidBackground: Bool {
        accessibility.reduceTransparency || systemReduceTransparency
    }

    private var title: String {
        switch event {
        case .charging: return "Charging"
        case .unplugged: return "Discharging"
        case .lowBattery: return "Low Battery"
        case .fullyCharged: return "Fully Charged"
        }
    }

    private var systemImage: String {
        switch event {
        case .charging: return "bolt.fill"
        case .unplugged: return "battery.75"
        case .lowBattery: return "exclamationmark.triangle.fill"
        case .fullyCharged: return "battery.100.bolt"
        }
    }

    private var accent: Color {
        switch event {
        case .charging:
            return Color(red: 0.12, green: 0.84, blue: 0.34)
        case .unplugged:
            return Color(red: 0.16, green: 0.55, blue: 1.00)
        case .lowBattery:
            return Color(red: 1.00, green: 0.25, blue: 0.22)
        case .fullyCharged:
            return Color(red: 0.08, green: 0.78, blue: 0.94)
        }
    }

    private var secondaryAccent: Color {
        switch event {
        case .charging:
            return Color(red: 0.08, green: 0.66, blue: 0.24)
        case .unplugged:
            return Color(red: 0.24, green: 0.36, blue: 0.96)
        case .lowBattery:
            return Color(red: 1.00, green: 0.58, blue: 0.08)
        case .fullyCharged:
            return Color(red: 0.16, green: 0.48, blue: 1.00)
        }
    }

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [accent, secondaryAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [accent.opacity(0.17), secondaryAccent.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )

            Text(title)
                .font(.system(
                    size: 14,
                    weight: accessibility.boldText ? .bold : .semibold
                ))
                .foregroundStyle(.primary)

            Text("\(event.percentage)%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(accent)
                .monospacedDigit()

            Spacer(minLength: 4)
        }
        .padding(.leading, 12)
        .padding(.trailing, 34)
        .frame(width: 280, height: 56)
        .background {
            let shape = Capsule()
            Group {
                if usesSolidBackground {
                    shape.fill(AppPalette.raisedSurface)
                } else {
                    shape
                        .fill(.ultraThinMaterial)
                        .overlay(
                            shape.fill(
                                LinearGradient(
                                    colors: [
                                        accent.opacity(0.075),
                                        secondaryAccent.opacity(0.025)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                }
            }
            .overlay(
                shape.strokeBorder(
                    accessibility.increaseContrast
                        ? Color.primary.opacity(0.42)
                        : accent.opacity(0.28),
                    lineWidth: accessibility.increaseContrast ? 1.5 : 0.75
                )
            )
        }
        .overlay(alignment: .trailing) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.16))
                    .frame(width: 14, height: 14)
                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)
            }
            .padding(.trailing, 14)
        }
        .shadow(color: accent.opacity(0.08), radius: 10, y: 3)
        .shadow(color: .black.opacity(0.22), radius: 12, y: 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(event.percentage) percent")
    }
}
