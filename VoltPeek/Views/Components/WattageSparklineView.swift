import Charts
import SwiftUI

/// Interactive ten-minute signed-wattage chart for the standalone app.
struct WattageSparklineView: View {
    let samples: [WattageSample]
    let latestWatts: Double?
    var displayWatts: (Double?) -> String
    var chartHeight: CGFloat = 200

    @Environment(\.appScale) private var scale
    @Environment(\.themeAccessibility) private var a11y
    @State private var selectedSample: WattageSample?

    private let chargeColor = Color(red: 0.043, green: 0.561, blue: 0.416)
    private let dischargeColor = Color.orange

    var body: some View {
        VStack(alignment: .leading, spacing: 16 * scale) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3 * scale) {
                    Text("Live Power")
                        .font(.system(size: 16 * scale, weight: .semibold))
                    Text("Last 10 minutes · \(samples.count) samples")
                        .font(.system(size: 11 * scale))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(displayWatts(latestWatts))
                    .font(.system(size: 22 * scale, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(lineColor)
            }

            statisticsGrid

            Chart {
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(Color.secondary.opacity(a11y.increaseContrast ? 0.65 : 0.38))
                    .lineStyle(StrokeStyle(lineWidth: a11y.increaseContrast ? 1.5 : 1, dash: [5, 4]))

                ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
                    AreaMark(
                        x: .value("Time", sample.date),
                        yStart: .value("Zero", 0),
                        yEnd: .value("Power", sample.watts)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [lineColor.opacity(0.28), lineColor.opacity(0.03)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Time", sample.date),
                        y: .value("Power", sample.watts)
                    )
                    .foregroundStyle(lineColor)
                    .lineStyle(StrokeStyle(
                        lineWidth: a11y.increaseContrast ? 3 : 2,
                        lineCap: .round,
                        lineJoin: .round
                    ))
                }

                if let selectedSample {
                    RuleMark(x: .value("Selected time", selectedSample.date))
                        .foregroundStyle(Color.primary.opacity(0.4))

                    PointMark(
                        x: .value("Selected time", selectedSample.date),
                        y: .value("Selected power", selectedSample.watts)
                    )
                    .foregroundStyle(color(for: selectedSample.watts))
                    .symbolSize(55 * scale)
                    .annotation(position: .top, spacing: 8 * scale) {
                        tooltip(for: selectedSample)
                    }
                }
            }
            .chartYScale(domain: wattsRange.min...wattsRange.max)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.secondary.opacity(0.15))
                    AxisTick()
                    AxisValueLabel(format: .dateTime.minute().second())
                        .font(.system(size: 10 * scale))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.secondary.opacity(0.18))
                    AxisTick()
                    AxisValueLabel {
                        if let watts = value.as(Double.self) {
                            Text("\(watts, specifier: "%.0f") W")
                                .font(.system(size: 10 * scale))
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                updateSelection(at: location, proxy: proxy, geometry: geometry)
                            case .ended:
                                selectedSample = nil
                            }
                        }
                }
            }
            .frame(height: chartHeight)
            .overlay {
                if samples.count < 2 {
                    Text("Collecting power samples…")
                        .font(.system(size: 13 * scale))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(18 * scale)
        .background(
            RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                .fill(AppPalette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                .strokeBorder(
                    a11y.increaseContrast ? Color.primary.opacity(0.35) : AppPalette.border,
                    lineWidth: a11y.increaseContrast ? 2 : 1
                )
        )
        .accessibilityLabel(
            "Ten minute wattage graph. Current \(displayWatts(latestWatts)). "
                + "Minimum \(displayWatts(statistics.minimum)). "
                + "Average \(displayWatts(statistics.average)). "
                + "Maximum \(displayWatts(statistics.maximum))."
        )
    }

    private var statisticsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 105 * scale), spacing: 10 * scale)],
            spacing: 10 * scale
        ) {
            statistic("Current", latestWatts)
            statistic("Minimum", statistics.minimum)
            statistic("Average", statistics.average)
            statistic("Maximum", statistics.maximum)
        }
    }

    private func statistic(_ title: String, _ value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4 * scale) {
            Text(title)
                .font(.system(size: 10 * scale))
                .foregroundStyle(.secondary)
            Text(displayWatts(value))
                .font(.system(size: 14 * scale, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(color(for: value))
        }
        .padding(10 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                .fill(AppPalette.raisedSurface)
        )
    }

    private func tooltip(for sample: WattageSample) -> some View {
        VStack(alignment: .leading, spacing: 3 * scale) {
            Text(displayWatts(sample.watts))
                .font(.system(size: 12 * scale, weight: .semibold))
                .monospacedDigit()
            Text(sample.date, format: .dateTime.hour().minute().second())
                .font(.system(size: 10 * scale))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 9 * scale)
        .padding(.vertical, 7 * scale)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 7 * scale))
        .shadow(color: .black.opacity(0.16), radius: 4 * scale, y: 2 * scale)
    }

    private var statistics: (minimum: Double?, average: Double?, maximum: Double?) {
        guard !samples.isEmpty else { return (nil, nil, nil) }
        let values = samples.map(\.watts)
        return (
            values.min(),
            values.reduce(0, +) / Double(values.count),
            values.max()
        )
    }

    private var lineColor: Color {
        color(for: latestWatts)
    }

    private func color(for watts: Double?) -> Color {
        guard let watts else { return .secondary }
        if a11y.differentiateWithoutColor {
            return .primary
        }
        if watts > 0.05 { return chargeColor }
        if watts < -0.05 { return dischargeColor }
        return .secondary
    }

    private var wattsRange: (min: Double, max: Double) {
        let values = samples.map(\.watts)
        var minimum = min(values.min() ?? -1, 0)
        var maximum = max(values.max() ?? 1, 0)
        if abs(maximum - minimum) < 1 {
            maximum += 1
            minimum -= 1
        }
        let padding = (maximum - minimum) * 0.12
        return (minimum - padding, maximum + padding)
    }

    private func updateSelection(
        at location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        guard let plotFrame = proxy.plotFrame else { return }
        let frame = geometry[plotFrame]
        let xPosition = location.x - frame.origin.x
        guard xPosition >= 0,
              xPosition <= frame.width,
              let date: Date = proxy.value(atX: xPosition) else {
            selectedSample = nil
            return
        }

        selectedSample = samples.min {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        }
    }
}
