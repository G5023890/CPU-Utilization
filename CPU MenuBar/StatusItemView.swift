import AppKit

@MainActor
final class StatusItemView: NSView {
    private let symbolImage: NSImage = {
        let image = NSImage(systemSymbolName: "memorychip.fill", accessibilityDescription: "CPU usage")!
        image.isTemplate = true
        return image
    }()
    private var displayText = "--"
    private var displayColor = NSColor.labelColor
    private let textShadow: NSShadow = {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.7)
        shadow.shadowBlurRadius = 1.5
        shadow.shadowOffset = NSSize(width: 0, height: -0.4)
        return shadow
    }()
    var onLeftClick: (() -> Void)?
    var onRightClick: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 48, height: 24)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        self
    }

    override func mouseUp(with event: NSEvent) {
        onLeftClick?()
    }

    override func rightMouseUp(with event: NSEvent) {
        onRightClick?()
    }

    func update(text: String, color: NSColor) {
        displayText = text
        displayColor = color.withAlphaComponent(0.95)
        needsDisplay = true
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let bounds = self.bounds

        let symbolSize = NSSize(width: 28, height: 28)
        let symbolRect = NSRect(
            x: bounds.midX - (symbolSize.width / 2),
            y: bounds.midY - (symbolSize.height / 2),
            width: symbolSize.width,
            height: symbolSize.height
        )

        displayColor.set()
        symbolImage.draw(
            in: symbolRect,
            from: NSRect(origin: .zero, size: symbolImage.size),
            operation: .sourceOver,
            fraction: 1
        )

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .bold),
            .foregroundColor: NSColor.white,
            .shadow: textShadow
        ]
        let attributedText = NSAttributedString(string: displayText, attributes: textAttributes)
        let textSize = attributedText.size()
        let textRect = NSRect(
            x: bounds.midX - (textSize.width / 2),
            y: bounds.midY - (textSize.height / 2),
            width: textSize.width,
            height: textSize.height
        )

        attributedText.draw(in: textRect)
    }
}
