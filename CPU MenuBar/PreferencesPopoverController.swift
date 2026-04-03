import AppKit
import SwiftUI

@MainActor
final class PreferencesPopoverController {
    private let popover: NSPopover

    init(preferences: AppPreferences) {
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 280, height: 180)
        popover.contentViewController = NSHostingController(
            rootView: PreferencesView(preferences: preferences)
                .frame(width: 280, height: 180)
        )
    }

    var isShown: Bool {
        popover.isShown
    }

    func show(relativeTo view: NSView) {
        popover.show(
            relativeTo: view.bounds,
            of: view,
            preferredEdge: .minY
        )
    }

    func close() {
        popover.close()
    }
}
