import AppKit
import SwiftUI

@MainActor
final class StatusItemView: NSView {
    private let hostingView: NSHostingView<CPUIndicatorView>

    init(viewModel: CPUIndicatorViewModel) {
        hostingView = NSHostingView(rootView: CPUIndicatorView(viewModel: viewModel))
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 32, height: 22)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
