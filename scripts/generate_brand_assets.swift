import AppKit
import Foundation

enum AssetRenderer {
    static let iconTop = NSColor(calibratedRed: 0.15, green: 0.17, blue: 0.22, alpha: 1.0).cgColor
    static let iconBottom = NSColor(calibratedRed: 0.06, green: 0.07, blue: 0.10, alpha: 1.0).cgColor
    static let iconHighlight = NSColor.white.withAlphaComponent(0.16).cgColor
    static let iconShadow = NSColor.black.withAlphaComponent(0.36).cgColor
    static let ringTrack = NSColor.white.withAlphaComponent(0.28).cgColor
    static let ringActive = NSColor.white.withAlphaComponent(0.92).cgColor
    static let ringGlow = NSColor.white.withAlphaComponent(0.10).cgColor
    static let textColor = NSColor.white.withAlphaComponent(0.96)

    static func makeBitmap(size: Int, draw: (CGContext, CGSize) -> Void) -> NSBitmapImageRep {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: size,
            pixelsHigh: size,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!

        guard let cgContext = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else {
            fatalError("Unable to create graphics context")
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        cgContext.setShouldAntialias(true)
        cgContext.setAllowsAntialiasing(true)
        cgContext.interpolationQuality = .high
        draw(cgContext, CGSize(width: size, height: size))
        NSGraphicsContext.restoreGraphicsState()
        return rep
    }

    static func writePNG(_ rep: NSBitmapImageRep, to url: URL) throws {
        guard let data = rep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "AssetRenderer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
        }
        try data.write(to: url)
    }

    static func drawRoundedRectBackground(_ ctx: CGContext, rect: CGRect, radius: CGFloat) {
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [iconTop, iconBottom] as CFArray,
            locations: [0, 1]
        )!
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.midX, y: rect.minY),
            end: CGPoint(x: rect.midX, y: rect.maxY),
            options: []
        )
        ctx.restoreGState()
    }

    static func drawGlassHighlight(_ ctx: CGContext, rect: CGRect, radius: CGFloat) {
        let highlight = CGRect(
            x: rect.minX + rect.width * 0.08,
            y: rect.minY + rect.height * 0.05,
            width: rect.width * 0.84,
            height: rect.height * 0.36
        )
        let path = CGPath(roundedRect: highlight, cornerWidth: radius * 0.6, cornerHeight: radius * 0.6, transform: nil)
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [iconHighlight, NSColor.white.withAlphaComponent(0.0).cgColor] as CFArray,
            locations: [0, 1]
        )!
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: highlight.midX, y: highlight.minY),
            end: CGPoint(x: highlight.midX, y: highlight.maxY),
            options: []
        )
        ctx.restoreGState()
    }

    static func drawRing(_ ctx: CGContext, center: CGPoint, radius: CGFloat, lineWidth: CGFloat, progress: CGFloat) {
        let startAngle: CGFloat = 135
        let fullSweep: CGFloat = 270
        let activeSweep = max(4, min(fullSweep, fullSweep * progress))

        func addArc(_ sweep: CGFloat, strokeColor: CGColor, width: CGFloat) {
            ctx.beginPath()
            ctx.addArc(center: center, radius: radius, startAngle: startAngle * .pi / 180, endAngle: (startAngle + sweep) * .pi / 180, clockwise: false)
            ctx.setStrokeColor(strokeColor)
            ctx.setLineWidth(width)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.strokePath()
        }

        addArc(fullSweep, strokeColor: ringTrack, width: lineWidth)
        addArc(activeSweep, strokeColor: ringActive, width: lineWidth)

        ctx.beginPath()
        ctx.addArc(center: center, radius: radius + lineWidth * 0.12, startAngle: startAngle * .pi / 180, endAngle: (startAngle + activeSweep) * .pi / 180, clockwise: false)
        ctx.setStrokeColor(ringGlow)
        ctx.setLineWidth(max(1, lineWidth * 0.18))
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.strokePath()
    }

    static func drawText(_ text: String, in rect: CGRect, size: CGFloat, color: NSColor, weight: NSFont.Weight, opacity: CGFloat) {
        let font = NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byClipping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color.withAlphaComponent(opacity),
            .paragraphStyle: paragraph,
            .kern: -0.03 * size
        ]
        let attr = NSAttributedString(string: text, attributes: attributes)
        let textSize = attr.size()
        let drawRect = CGRect(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2 - size * 0.02,
            width: textSize.width,
            height: textSize.height
        )
        attr.draw(in: drawRect)
    }
}

func renderIcon(size: Int, value: Int = 24) -> NSBitmapImageRep {
    AssetRenderer.makeBitmap(size: size) { ctx, canvas in
        let rect = CGRect(origin: .zero, size: canvas)
        let radius = canvas.width * 0.22
        AssetRenderer.drawRoundedRectBackground(ctx, rect: rect, radius: radius)
        AssetRenderer.drawGlassHighlight(ctx, rect: rect, radius: radius)

        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -canvas.width * 0.01), blur: canvas.width * 0.045, color: AssetRenderer.iconShadow)
        let ringCenter = CGPoint(x: rect.midX, y: rect.midY + canvas.height * 0.01)
        let ringRadius = canvas.width * 0.27
        let lineWidth = max(1.2, canvas.width * 0.060)
        AssetRenderer.drawRing(ctx, center: ringCenter, radius: ringRadius, lineWidth: lineWidth, progress: 0.34)
        ctx.restoreGState()

        let textRect = CGRect(x: canvas.width * 0.17, y: canvas.height * 0.20, width: canvas.width * 0.66, height: canvas.height * 0.60)
        let textSize: CGFloat
        switch value {
        case 100: textSize = canvas.width * 0.19
        case 10...99: textSize = canvas.width * 0.24
        default: textSize = canvas.width * 0.27
        }

        ctx.setShadow(offset: CGSize(width: 0, height: -canvas.width * 0.006), blur: canvas.width * 0.016, color: NSColor.black.withAlphaComponent(0.28).cgColor)

        AssetRenderer.drawText("\(value)", in: textRect, size: textSize, color: AssetRenderer.textColor, weight: .semibold, opacity: 0.98)
    }
}

func renderPreview(size: CGSize) -> NSBitmapImageRep {
    AssetRenderer.makeBitmap(size: Int(size.width)) { ctx, canvas in
        let rect = CGRect(origin: .zero, size: canvas)
        let bg = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [NSColor(calibratedWhite: 0.98, alpha: 1.0).cgColor, NSColor(calibratedWhite: 0.92, alpha: 1.0).cgColor] as CFArray,
            locations: [0, 1]
        )!
        ctx.drawLinearGradient(bg, start: CGPoint(x: rect.midX, y: rect.minY), end: CGPoint(x: rect.midX, y: rect.maxY), options: [])

        let menuBarHeight = canvas.height * 0.11
        let menuBar = CGRect(x: 0, y: canvas.height - menuBarHeight, width: canvas.width, height: menuBarHeight)
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.65).cgColor)
        ctx.fill(menuBar)

        let cardRect = CGRect(x: canvas.width * 0.07, y: canvas.height * 0.18, width: canvas.width * 0.38, height: canvas.height * 0.60)
        let cardPath = CGPath(roundedRect: cardRect, cornerWidth: 36, cornerHeight: 36, transform: nil)
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 26, color: NSColor.black.withAlphaComponent(0.14).cgColor)
        ctx.addPath(cardPath)
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fillPath()
        ctx.restoreGState()

        if let icon = renderIcon(size: 1024).cgImage {
            ctx.draw(icon, in: CGRect(x: canvas.width * 0.12, y: canvas.height * 0.41, width: canvas.width * 0.16, height: canvas.width * 0.16))
        }

        AssetRenderer.drawText("CPU MenuBar", in: CGRect(x: canvas.width * 0.12, y: canvas.height * 0.30, width: canvas.width * 0.28, height: canvas.height * 0.07), size: canvas.width * 0.035, color: NSColor(calibratedWhite: 0.12, alpha: 1.0), weight: .semibold, opacity: 0.95)
        AssetRenderer.drawText("ultra-minimal menu bar CPU indicator", in: CGRect(x: canvas.width * 0.12, y: canvas.height * 0.25, width: canvas.width * 0.30, height: canvas.height * 0.05), size: canvas.width * 0.020, color: NSColor(calibratedWhite: 0.35, alpha: 1.0), weight: .medium, opacity: 0.92)

        if let indicator = renderIcon(size: 1024, value: 24).cgImage {
            let indicatorRect = CGRect(x: canvas.width * 0.75, y: canvas.height * 0.605, width: canvas.width * 0.14, height: canvas.width * 0.14)
            ctx.draw(indicator, in: indicatorRect)
        }
    }
}

let fm = FileManager.default
let root = URL(fileURLWithPath: fm.currentDirectoryPath)
let iconSetURL = root.appendingPathComponent("CPU MenuBar/Assets.xcassets/AppIcon.appiconset")
let previewURL = root.appendingPathComponent("CPU MenuBar/BrandAssets/cpu-menubar-preview.png")

let iconSpecs: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, pixels) in iconSpecs {
    let rep = renderIcon(size: pixels)
    try AssetRenderer.writePNG(rep, to: iconSetURL.appendingPathComponent(name))
}

let preview = renderPreview(size: CGSize(width: 1600, height: 1000))
try AssetRenderer.writePNG(preview, to: previewURL)

print("Generated app icons in \(iconSetURL.path)")
print("Generated preview at \(previewURL.path)")
