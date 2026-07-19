import AppKit
import SwiftUI

/// Menu bar battery glyph — Design D (outline bolt) with optional level-colored fill.
struct SystemMenuBarBatteryIcon: View {
    var percentage: Int
    var isCharging: Bool = false
    var accessibility: AccessibilityPreferences = .default
    var appearance: MenuBarBatteryAppearance = .colored
    /// Menu-bar point size (matches typical status-item height).
    var height: CGFloat = 11

    var body: some View {
        Image(nsImage: Self.makeMenuBarBatteryImage(
            percentage: percentage,
            isCharging: isCharging,
            height: height,
            accessibility: accessibility,
            appearance: appearance
        ))
        .renderingMode(.original)
        .accessibilityHidden(true)
    }

    /// Level bands matching the approved D-variant color sheet.
    static func fillColor(
        for percentage: Int,
        accessibility: AccessibilityPreferences,
        appearance: MenuBarBatteryAppearance
    ) -> NSColor {
        if appearance == .monochrome || accessibility.differentiateWithoutColor {
            let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? .white : .black
        }
        let pct = max(0, min(100, percentage))
        switch pct {
        case 0...20: return NSColor(srgbRed: 1.0, green: 0.271, blue: 0.227, alpha: 1)      // #FF453A
        case 21...40: return NSColor(srgbRed: 1.0, green: 0.624, blue: 0.039, alpha: 1)     // #FF9F0A
        case 41...70: return NSColor(srgbRed: 1.0, green: 0.839, blue: 0.039, alpha: 1)     // #FFD60A
        default: return NSColor(srgbRed: 0.188, green: 0.820, blue: 0.345, alpha: 1)        // #30D158
        }
    }

    static func makeMenuBarBatteryImage(
        percentage: Int,
        isCharging: Bool,
        height: CGFloat,
        accessibility: AccessibilityPreferences = .default,
        appearance: MenuBarBatteryAppearance = .colored
    ) -> NSImage {
        let pct = max(0, min(100, percentage))
        let clamped = CGFloat(pct) / 100
        let isLow = pct < 20 && !isCharging
        let showLowMark = isLow && accessibility.differentiateWithoutColor

        let stroke: CGFloat = accessibility.increaseContrast ? 1.55 : 1.3
        let tipWidth = height * 0.16
        let tipHeight = height * 0.42
        let bodyWidth = height * 2.29
        let markGap: CGFloat = showLowMark ? 3 : 0
        let markWidth: CGFloat = showLowMark ? ceil(height * 0.55) : 0
        let totalWidth = bodyWidth + tipWidth + markGap + markWidth
        let corner = height * 0.36
        let inset: CGFloat = accessibility.increaseContrast ? 1.45 : 1.7
        let pointSize = NSSize(width: ceil(totalWidth), height: ceil(height))
        let scale = max(NSScreen.main?.backingScaleFactor ?? 2, 2)

        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        // Explicit colors — `labelColor` resolves poorly in offscreen bitmaps.
        let shellColor: NSColor = isDark ? .white : .black
        let fill = fillColor(for: pct, accessibility: accessibility, appearance: appearance)
        let monochrome = appearance == .monochrome || accessibility.differentiateWithoutColor

        let image = NSImage(size: pointSize, flipped: false) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

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
            ctx.setStrokeColor(shellColor.cgColor)
            ctx.setLineWidth(stroke)
            ctx.addPath(shell)
            ctx.strokePath()

            let tipPath = CGPath(
                roundedRect: tipRect,
                cornerWidth: tipHeight * 0.4,
                cornerHeight: tipHeight * 0.4,
                transform: nil
            )
            ctx.setFillColor(shellColor.cgColor)
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
                ctx.setFillColor(fill.cgColor)
                ctx.addPath(fillPath)
                ctx.fillPath()
            }

            if isCharging {
                drawOutlineBolt(in: ctx, body: bodyRect, height: height, monochrome: monochrome)
            }

            if showLowMark {
                let mark = "!" as NSString
                let fontSize = height * 0.95
                let weight: NSFont.Weight = accessibility.boldText ? .heavy : .bold
                let font = NSFont.systemFont(ofSize: fontSize, weight: weight)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: shellColor
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
            crisp.isTemplate = false
            return crisp
        }

        image.isTemplate = false
        return image
    }

    /// Full Both label in one image — MenuBarExtra drops multi-view HStacks.
    /// Order: power bolt, watts, middle dot, percent, battery.
    static func makeBothLabelImage(
        wattsText: String,
        percentage: Int,
        isCharging: Bool,
        accessibility: AccessibilityPreferences = .default,
        appearance: MenuBarBatteryAppearance = .colored,
        height: CGFloat = 12
    ) -> NSImage {
        let monochrome = appearance == .monochrome || accessibility.differentiateWithoutColor
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let textColor: NSColor = isDark ? .white : .black
        let boltColor: NSColor = monochrome
            ? textColor
            : NSColor(srgbRed: 1.0, green: 0.84, blue: 0.04, alpha: 1)

        let baseFont = NSFont.menuBarFont(ofSize: 0)
        let font: NSFont = accessibility.boldText
            ? NSFont.systemFont(ofSize: baseFont.pointSize, weight: .bold)
            : baseFont
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let secondaryAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor.withAlphaComponent(0.65)
        ]

        let wattsSize = (wattsText as NSString).size(withAttributes: textAttrs)
        let dot = "·" as NSString
        let dotSize = dot.size(withAttributes: secondaryAttrs)
        let percentText = "\(percentage)%" as NSString
        let percentSize = percentText.size(withAttributes: textAttrs)

        let battery = makeMenuBarBatteryImage(
            percentage: percentage,
            isCharging: isCharging,
            height: height,
            accessibility: accessibility,
            appearance: appearance
        )

        let boltSize = height * 0.95
        let gap: CGFloat = 4
        let pointSize = NSSize(
            width: ceil(boltSize + gap + wattsSize.width + gap + dotSize.width + gap + percentSize.width + gap + battery.size.width),
            height: max(ceil(wattsSize.height), ceil(height), ceil(boltSize))
        )
        let scale = max(NSScreen.main?.backingScaleFactor ?? 2, 2)

        let image = NSImage(size: pointSize, flipped: false) { _ in
            var x: CGFloat = 0
            let midY = pointSize.height / 2

            // Power bolt
            if let bolt = Self.tintedBolt(color: boltColor, pointSize: boltSize * 0.85) {
                let boltRect = NSRect(
                    x: x,
                    y: midY - boltSize / 2,
                    width: boltSize,
                    height: boltSize
                )
                bolt.draw(in: boltRect, from: .zero, operation: .sourceOver, fraction: 1)
            }
            x += boltSize + gap

            (wattsText as NSString).draw(
                at: NSPoint(x: x, y: midY - wattsSize.height / 2),
                withAttributes: textAttrs
            )
            x += wattsSize.width + gap

            dot.draw(
                at: NSPoint(x: x, y: midY - dotSize.height / 2),
                withAttributes: secondaryAttrs
            )
            x += dotSize.width + gap

            percentText.draw(
                at: NSPoint(x: x, y: midY - percentSize.height / 2),
                withAttributes: textAttrs
            )
            x += percentSize.width + gap

            battery.draw(
                in: NSRect(
                    x: x,
                    y: midY - battery.size.height / 2,
                    width: battery.size.width,
                    height: battery.size.height
                ),
                from: .zero,
                operation: .sourceOver,
                fraction: 1,
                respectFlipped: true,
                hints: [.interpolation: NSImageInterpolation.high]
            )
            return true
        }

        return crispen(image, pointSize: pointSize, scale: scale)
    }

    /// Watts-only composite: bolt + watts text.
    static func makeWattsLabelImage(
        wattsText: String,
        accessibility: AccessibilityPreferences = .default,
        appearance: MenuBarBatteryAppearance = .colored,
        height: CGFloat = 12
    ) -> NSImage {
        let monochrome = appearance == .monochrome || accessibility.differentiateWithoutColor
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let textColor: NSColor = isDark ? .white : .black
        let boltColor: NSColor = monochrome
            ? textColor
            : NSColor(srgbRed: 1.0, green: 0.84, blue: 0.04, alpha: 1)

        let baseFont = NSFont.menuBarFont(ofSize: 0)
        let font: NSFont = accessibility.boldText
            ? NSFont.systemFont(ofSize: baseFont.pointSize, weight: .bold)
            : baseFont
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let wattsSize = (wattsText as NSString).size(withAttributes: textAttrs)
        let boltSize = height * 0.95
        let gap: CGFloat = 3
        let pointSize = NSSize(
            width: ceil(boltSize + gap + wattsSize.width),
            height: max(ceil(wattsSize.height), ceil(boltSize))
        )
        let scale = max(NSScreen.main?.backingScaleFactor ?? 2, 2)

        let image = NSImage(size: pointSize, flipped: false) { _ in
            var x: CGFloat = 0
            let midY = pointSize.height / 2
            if let bolt = Self.tintedBolt(color: boltColor, pointSize: boltSize * 0.85) {
                bolt.draw(
                    in: NSRect(x: x, y: midY - boltSize / 2, width: boltSize, height: boltSize),
                    from: .zero,
                    operation: .sourceOver,
                    fraction: 1
                )
            }
            x += boltSize + gap
            (wattsText as NSString).draw(
                at: NSPoint(x: x, y: midY - wattsSize.height / 2),
                withAttributes: textAttrs
            )
            return true
        }

        return crispen(image, pointSize: pointSize, scale: scale)
    }

    private static func crispen(_ image: NSImage, pointSize: NSSize, scale: CGFloat) -> NSImage {
        guard let retina = NSBitmapImageRep(
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
        ) else {
            image.isTemplate = false
            return image
        }
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
        crisp.isTemplate = false
        return crisp
    }

    /// Colored mode: white core + dark halo. Monochrome: inverted for label-color fill.
    private static func drawOutlineBolt(
        in ctx: CGContext,
        body: CGRect,
        height: CGFloat,
        monochrome: Bool
    ) {
        let bolt = boltPath(in: body)
        let haloWidth = max(1.8, height * 0.22)
        let coreWidth = max(1.0, height * 0.12)

        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let halo: NSColor
        let core: NSColor
        if monochrome {
            halo = isDark ? NSColor.white : NSColor.black.withAlphaComponent(0.92)
            core = isDark ? NSColor.black.withAlphaComponent(0.92) : NSColor.white
        } else {
            halo = NSColor.black.withAlphaComponent(0.92)
            core = NSColor.white
        }

        ctx.saveGState()
        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)
        ctx.setStrokeColor(halo.cgColor)
        ctx.setLineWidth(haloWidth)
        ctx.addPath(bolt)
        ctx.strokePath()

        ctx.setStrokeColor(core.cgColor)
        ctx.setLineWidth(coreWidth)
        ctx.addPath(bolt)
        ctx.strokePath()
        ctx.restoreGState()
    }

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

    private static func tintedBolt(color: NSColor, pointSize: CGFloat) -> NSImage? {
        guard let symbol = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil) else {
            return nil
        }
        let sizeConfig = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        let colorConfig = NSImage.SymbolConfiguration(paletteColors: [color])
        let configured = symbol
            .withSymbolConfiguration(sizeConfig)?
            .withSymbolConfiguration(colorConfig) ?? symbol
        configured.isTemplate = false
        return configured
    }
}
