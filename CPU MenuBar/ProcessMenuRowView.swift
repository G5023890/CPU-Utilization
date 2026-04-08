import AppKit

@MainActor
final class ProcessMenuRowView: NSView {
    private let nameLabel = NSTextField(labelWithString: "")
    private let percentLabel = NSTextField(labelWithString: "")

    init(name: String, cpuPercent: Double) {
        super.init(frame: .zero)
        configure(name: name, cpuPercent: cpuPercent)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 320, height: 24)
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        nameLabel.textColor = .labelColor
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.maximumNumberOfLines = 1
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        percentLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        percentLabel.alignment = .right
        percentLabel.lineBreakMode = .byClipping
        percentLabel.textColor = .labelColor
        percentLabel.setContentHuggingPriority(.required, for: .horizontal)
        percentLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stack = NSStackView(views: [nameLabel, percentLabel])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.distribution = .fill
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            percentLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
    }

    private func configure(name: String, cpuPercent: Double) {
        nameLabel.stringValue = name
        percentLabel.stringValue = String(format: "%.0f%%", cpuPercent)
    }
}
