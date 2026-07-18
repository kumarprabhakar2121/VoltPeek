import SwiftUI

/// One-minute signed wattage sparkline for the popover footer area.
struct WattageSparklineView: View {
    let samples: [WattageSample]
    let latestWatts: Double?
    var displayWatts: (Double?) -> String
    var chartHeight: CGFloat = 56

    @Environment(\.themeScale) private var scale
    @Environment(\.themeTypography) private var type
    @Environment(\.themeAccessibility) private var a11y

    private let chargeColor = Color(red: 0.043, green: 0.561, blue: 0.416)
    private let dischargeColor = Color.orange

    var body: some View {
        VStack(alignment: .leading, spacing: 6 * scale) {
            HStack {
                Text("Power · 1m")
                    .font(type.caption)
                    .foregroundStyle(a11y.increaseContrast ? Color.primary : Color.secondary)
                Spacer()
                Text(displayWatts(latestWatts))
                    .font(type.metric)
                    .monospacedDigit()
                    .foregroundStyle(lineColor)
            }

            GeometryReader { geo in
                let size = geo.size
                ZStack {
                    Path { path in
                        let y = yPosition(for: 0, in: size)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    .stroke(Color.secondary.opacity(a11y.increaseContrast ? 0.45 : 0.25), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    if samples.count >= 2 {
                        fillPath(in: size)
                            .fill(lineColor.opacity(a11y.reduceTransparency ? 0.18 : 0.22))
                        linePath(in: size)
                            .stroke(lineColor, style: StrokeStyle(lineWidth: a11y.increaseContrast ? 2.2 : 1.6, lineJoin: .round))
                    } else {
                        Text("Collecting samples…")
                            .font(type.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .frame(height: chartHeight * scale)
        }
        .padding(10 * scale)
        .background(
            RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                .strokeBorder(Color.primary.opacity(a11y.increaseContrast ? 0.35 : 0.12), lineWidth: a11y.increaseContrast ? 2 : 1)
        )
        .accessibilityLabel("One minute wattage graph, \(displayWatts(latestWatts))")
    }

    private var lineColor: Color {
        guard let w = latestWatts else { return .secondary }
        if a11y.differentiateWithoutColor {
            return .primary
        }
        if w > 0.05 { return chargeColor }
        if w < -0.05 { return dischargeColor }
        return .secondary
    }

    private var wattsRange: (min: Double, max: Double) {
        let values = samples.map(\.watts)
        var minV = values.min() ?? -1
        var maxV = values.max() ?? 1
        minV = min(minV, 0)
        maxV = max(maxV, 0)
        if abs(maxV - minV) < 1 {
            maxV += 1
            minV -= 1
        }
        // Padding
        let pad = (maxV - minV) * 0.08
        return (minV - pad, maxV + pad)
    }

    private func yPosition(for watts: Double, in size: CGSize) -> CGFloat {
        let range = wattsRange
        let span = range.max - range.min
        guard span > 0 else { return size.height / 2 }
        let normalized = (watts - range.min) / span
        return size.height - CGFloat(normalized) * size.height
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard let first = samples.first, let last = samples.last, last.date > first.date else {
            return []
        }
        let duration = last.date.timeIntervalSince(first.date)
        return samples.map { sample in
            let t = sample.date.timeIntervalSince(first.date) / duration
            return CGPoint(x: CGFloat(t) * size.width, y: yPosition(for: sample.watts, in: size))
        }
    }

    private func linePath(in size: CGSize) -> Path {
        let pts = points(in: size)
        return Path { path in
            guard let first = pts.first else { return }
            path.move(to: first)
            for point in pts.dropFirst() {
                path.addLine(to: point)
            }
        }
    }

    private func fillPath(in size: CGSize) -> Path {
        let pts = points(in: size)
        let zeroY = yPosition(for: 0, in: size)
        return Path { path in
            guard let first = pts.first, let last = pts.last else { return }
            path.move(to: CGPoint(x: first.x, y: zeroY))
            path.addLine(to: first)
            for point in pts.dropFirst() {
                path.addLine(to: point)
            }
            path.addLine(to: CGPoint(x: last.x, y: zeroY))
            path.closeSubpath()
        }
    }
}
