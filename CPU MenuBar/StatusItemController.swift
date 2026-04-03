import AppKit

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let statusItemView = StatusItemView()
    private let preferences: AppPreferences
    private let cpuMonitor = CPUUsageMonitor()
    private let preferencesPopover: PreferencesPopoverController
    private let statusMenu = NSMenu()
    private var timer: Timer?
    private var lastShownPercent: Int?

    init(preferences: AppPreferences) {
        self.preferences = preferences
        statusItem = NSStatusBar.system.statusItem(withLength: 48)
        preferencesPopover = PreferencesPopoverController(preferences: preferences)
        super.init()

        NSLog("CPU MenuBar status item created: %@", statusItem)
        configureStatusItem()
        configureMenu()
        preferences.onChange = { [weak self] in
            self?.refreshDisplayedTitle()
        }
    }

    func start() {
        cpuMonitor.prime()
        updateStatusItem(using: displayText(for: nil), percent: nil)
        scheduleUpdates()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.title = ""
        button.image = nil
        button.imagePosition = .noImage
        button.toolTip = "CPU usage"
        button.setAccessibilityLabel("CPU usage")
        button.isBordered = false

        statusItemView.onLeftClick = { [weak self] in
            self?.togglePreferencesPopover()
        }
        statusItemView.onRightClick = { [weak self] in
            if self?.preferencesPopover.isShown == true {
                self?.preferencesPopover.close()
            }
            self?.showContextMenu()
        }

        statusItemView.frame = button.bounds
        statusItemView.autoresizingMask = [.width, .height]
        button.addSubview(statusItemView)
    }

    private func configureMenu() {
        statusMenu.autoenablesItems = false

        let preferencesItem = NSMenuItem(
            title: "Preferences…",
            action: #selector(showPreferences(_:)),
            keyEquivalent: ","
        )
        preferencesItem.target = self
        statusMenu.addItem(preferencesItem)

        statusMenu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit CPU MenuBar",
            action: #selector(quitApp(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        statusMenu.addItem(quitItem)
    }

    private func scheduleUpdates() {
        guard timer == nil else {
            return
        }

        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshCPUUsage()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func refreshCPUUsage() {
        guard let usage = cpuMonitor.sampleUsage() else {
            return
        }

        let percent = max(0, min(100, Int((usage * 100).rounded())))
        lastShownPercent = percent

        updateStatusItem(using: displayText(for: percent), percent: percent)
    }

    private func refreshDisplayedTitle() {
        guard let lastShownPercent else {
            return
        }

        updateStatusItem(using: displayText(for: lastShownPercent), percent: lastShownPercent)
    }

    private func updateStatusItem(using text: String, percent: Int?) {
        statusItemView.update(text: text, color: resolvedTitleColor(for: percent))
        NSLog("CPU MenuBar updated status item: %@", text)
    }

    private func displayText(for percent: Int?) -> String {
        switch percent {
        case .some(let value):
            return "\(value)"
        case .none:
            return "--"
        }
    }

    private func showContextMenu() {
        if preferencesPopover.isShown {
            preferencesPopover.close()
        }

        guard let event = NSApp.currentEvent else {
            return
        }

        guard let button = statusItem.button else {
            return
        }

        NSMenu.popUpContextMenu(statusMenu, with: event, for: button)
    }

    @objc private func showPreferences(_ sender: Any?) {
        togglePreferencesPopover()
    }

    private func togglePreferencesPopover() {
        guard let button = statusItem.button else {
            return
        }

        if preferencesPopover.isShown {
            preferencesPopover.close()
        } else {
            preferencesPopover.show(relativeTo: button)
        }
    }

    @objc private func quitApp(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    private func resolvedTitleColor(for percent: Int?) -> NSColor {
        guard
            preferences.highCpuColorEnabled,
            let percent,
            percent >= Int(preferences.highCpuThreshold)
        else {
            return .labelColor
        }

        return .systemRed
    }
}
