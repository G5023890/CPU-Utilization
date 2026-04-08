import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = StatusItemController()
        statusItemController?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusItemController?.stop()
    }
}
