import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private var preferences: AppPreferences?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let preferences = AppPreferences()
        self.preferences = preferences
        statusItemController = StatusItemController(preferences: preferences)
        statusItemController?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusItemController?.stop()
    }
}
