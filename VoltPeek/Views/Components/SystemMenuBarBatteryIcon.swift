import AppKit
import SwiftUI

/// Menu bar battery glyph matching the macOS status-item battery.
/// Drawn into a template `NSImage` so MenuBarExtra / Form cards always show fill + outline.
struct SystemMenuBarBatteryIcon: View {
    var percentage: Int
    var isCharging: Bool = false
    var accessibility: AccessibilityPreferences = .default
    /// Menu-bar point size (matches typical status-item height).
    var height: CGFloat = 11

    var body: some View {
        Image(nsImage: Self.makeTemplateImage(
            percentage: percentage,
            isCharging: isCharging,
            height: height,
            accessibility: accessibility
        ))
        .renderingMode(.template)
        .accessibilityHidden(true)
    }

    /// Black-on-clear drawing; system tints it for light/dark menu bar.
    static func makeTemplateImage(
        percentage: Int,
        isCharging: Bool,
        height: CGFloat,
        accessibility: AccessibilityPreferences = .default
    ) -> NSImage {
        let pct = max(0, min(100, percentage))
        let clamped = CGFloat(pct) / 100
        let isLow = pct < 20 && !isCharging
        let useRedLow = isLow && !accessibility.differentiateWithoutColor
        let showLowMark = isLow && accessibility.differentiateWithoutColor

        let stroke: CGFloat = accessibility.increaseContrast ? 1.6 : 1.15
        let inkAlpha: CGFloat = accessibility.reduceTransparency ? 1.0 : 0.95
        let tipWidth = height * 0.16
        let tipHeight = height * 0.42
        let bodyWidth = height * 2.29
        let markGap: CGFloat = showLowMark ? 3 : 0
        let markWidth: CGFloat = showLowMark ? ceil(height * 0.55) : 0
        let totalWidth = bodyWidth + tipWidth + markGap + markWidth
        let corner = height * 0.36
        let inset: CGFloat = accessibility.increaseContrast ? 1.5 : 1.75
        let pointSize = NSSize(width: ceil(totalWidth), height: ceil(height))
        let scale = max(NSScreen.main?.backingScaleFactor ?? 2, 2)

        let image = NSImage(size: pointSize, flipped: false) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            let ink = NSColor.black.withAlphaComponent(inkAlpha)
            let fillInk = useRedLow ? NSColor.red : ink

            let bodyRect = CGRect(x: 0, y: 0, width: bodyWidth, height: height)
            let tipRect = CGRect(
                x: bodyWidth - 0.5,
                y: (height - tipHeight) / 2,
                width: tipWidth,
                height: tipHeight
            )

            let shell = CGPath(
                roundedRect: bodyRect.insetBy(dx: stroke / 2, dy: stroke / 2),
                cornerWidth: corner,
                cornerHeight: corner,
                transform: nil
            )
            ctx.setStrokeColor(ink.cgColor)
            ctx.setLineWidth(stroke)
            ctx.addPath(shell)
            ctx.strokePath()

            let tipPath = CGPath(
                roundedRect: tipRect,
                cornerWidth: tipHeight * 0.4,
                cornerHeight: tipHeight * 0.4,
                transform: nil
            )
            ctx.setFillColor(ink.cgColor)
            ctx.addPath(tipPath)
            ctx.fillPath()

            let inner = bodyRect.insetBy(dx: inset, dy: inset)
            let fillWidth = max(0, inner.width * clamped)
            if fillWidth > 0.5 {
                let fillCorner = max(0.8, min(corner - inset * 0.6, fillWidth / 2))
                let fillRect = CGRect(x: inner.minX, y: inner.minY, width: fillWidth, height: inner.height)
                let fillPath = CGPath(
                    roundedRect: fillRect,
                    cornerWidth: fillCorner,
                    cornerHeight: fillCorner,
                    transform: nil
                )
                ctx.setFillColor(fillInk.cgColor)
                ctx.addPath(fillPath)
                ctx.fillPath()
            }

            // Charging only: punch a bolt cutout (negative space), like macOS Battery.
            if isCharging {
                cutOutBolt(in: ctx, body: bodyRect)
            }

            if showLowMark {
                let mark = "!" as NSString
                let fontSize = height * 0.95
                let weight: NSFont.Weight = accessibility.boldText ? .heavy : .bold
                let font = NSFont.systemFont(ofSize: fontSize, weight: weight)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: NSColor.black
                ]
                let markSize = mark.size(withAttributes: attrs)
                mark.draw(
                    at: NSPoint(
                        x: bodyWidth + tipWidth + markGap,
                        y: (height - markSize.height) / 2
                    ),
                    withAttributes: attrs
                )
            }

            return true
        }

        // Prefer a retina bitmap representation for crisp cutout edges in the menu bar.
        if let tiff = image.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff) {
            let retina = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(pointSize.width * scale),
                pixelsHigh: Int(pointSize.height * scale),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
            if let retina {
                retina.size = pointSize
                NSGraphicsContext.saveGraphicsState()
                if let gc = NSGraphicsContext(bitmapImageRep: retina) {
                    NSGraphicsContext.current = gc
                    image.draw(
                        in: NSRect(origin: .zero, size: pointSize),
                        from: .zero,
                        operation: .copy,
                        fraction: 1
                    )
                }
                NSGraphicsContext.restoreGraphicsState()
                let crisp = NSImage(size: pointSize)
                crisp.addRepresentation(retina)
                crisp.isTemplate = true
                return crisp
            }
            _ = rep
        }

        image.isTemplate = true
        return image
    }

    /// Combined “⚡ watts · percent + battery” label as one template image for MenuBarExtra.
    static func makeBothLabelImage(
        bothText: String,
        percentage: Int,
        isCharging: Bool,
        height: CGFloat = 12,
        accessibility: AccessibilityPreferences = .default
    ) -> NSImage {
        let baseFont = NSFont.menuBarFont(ofSize: 0)
        let font: NSFont = {
            if accessibility.boldText {
                return NSFont.systemFont(ofSize: baseFont.pointSize, weight: .bold)
            }
            return baseFont
        }()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black
        ]
        let textSize = (bothText as NSString).size(withAttributes: attrs)
        let batteryHeight = height
        let batteryImage = makeTemplateImage(
            percentage: percentage,
            isCharging: isCharging,
            height: batteryHeight,
            accessibility: accessibility
        )
        let batteryWidth = batteryImage.size.width
        let gap: CGFloat = 4
        let pointSize = NSSize(
            width: ceil(textSize.width) + gap + batteryWidth,
            height: max(ceil(textSize.height), ceil(batteryHeight))
        )
        let scale = max(NSScreen.main?.backingScaleFactor ?? 2, 2)

        let image = NSImage(size: pointSize, flipped: false) { _ in
            let textY = (pointSize.height - textSize.height) / 2
            (bothText as NSString).draw(
                at: NSPoint(x: 0, y: textY),
                withAttributes: attrs
            )

            let batteryOrigin = NSPoint(
                x: ceil(textSize.width) + gap,
                y: (pointSize.height - batteryHeight) / 2
            )
            batteryImage.draw(
                in: NSRect(origin: batteryOrigin, size: batteryImage.size),
                from: .zero,
                operation: .sourceOver,
                fraction: 1,
                respectFlipped: true,
                hints: [.interpolation: NSImageInterpolation.high]
            )
            return true
        }

        if let retina = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(pointSize.width * scale),
            pixelsHigh: Int(pointSize.height * scale),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) {
            retina.size = pointSize
            NSGraphicsContext.saveGraphicsState()
            if let gc = NSGraphicsContext(bitmapImageRep: retina) {
                NSGraphicsContext.current = gc
                image.draw(
                    in: NSRect(origin: .zero, size: pointSize),
                    from: .zero,
                    operation: .copy,
                    fraction: 1
                )
            }
            NSGraphicsContext.restoreGraphicsState()
            let crisp = NSImage(size: pointSize)
            crisp.addRepresentation(retina)
            crisp.isTemplate = true
            return crisp
        }

        image.isTemplate = true
        return image
    }

    /// Punches a transparent bolt through existing ink (macOS charging look).
    private static func cutOutBolt(in ctx: CGContext, body: CGRect) {
        let bolt = boltPath(in: body)
        ctx.saveGState()
        ctx.setBlendMode(.destinationOut)
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.addPath(bolt)
        ctx.fillPath()
        ctx.restoreGState()
    }

    /// Classic lightning shape, centered in the battery body (point space, y-up).
    private static func boltPath(in body: CGRect) -> CGPath {
        let cx = body.midX
        let cy = body.midY
        let s = min(body.width, body.height)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: cx + s * 0.06, y: cy + s * 0.42))
        path.addLine(to: CGPoint(x: cx - s * 0.20, y: cy + s * 0.02))
        path.addLine(to: CGPoint(x: cx - s * 0.02, y: cy + s * 0.02))
        path.addLine(to: CGPoint(x: cx - s * 0.10, y: cy - s * 0.42))
        path.addLine(to: CGPoint(x: cx + s * 0.20, y: cy - s * 0.02))
        path.addLine(to: CGPoint(x: cx + s * 0.02, y: cy - s * 0.02))
        path.closeSubpath()
        return path
    }
}
