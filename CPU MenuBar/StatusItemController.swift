import AppKit

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let viewModel = CPUIndicatorViewModel()
    private let processMonitor = ProcessCPUUsageMonitor()
    private let preferences = AppPreferences()
    private lazy var preferencesPopoverController = PreferencesPopoverController(preferences: preferences)
    private let processesMenu = NSMenu()
    private let statusItemView: StatusItemView

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: 32)
        statusItemView = StatusItemView(viewModel: viewModel)
        super.init()

        processMonitor.onChange = { [weak self] in
            self?.rebuildProcessesMenu()
        }

        configureStatusItem()
        configureProcessesMenu()
    }

    func start() {
        viewModel.start()
        processMonitor.start()
    }

    func stop() {
        viewModel.stop()
        processMonitor.stop()
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
        button.target = nil
        button.action = nil
        button.sendAction(on: [])
        statusItem.menu = processesMenu

        statusItemView.autoresizingMask = [.width, .height]
        button.addSubview(statusItemView)
        statusItemView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            statusItemView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            statusItemView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            statusItemView.topAnchor.constraint(equalTo: button.topAnchor),
            statusItemView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
    }

    private func configureProcessesMenu() {
        processesMenu.delegate = self
        processesMenu.autoenablesItems = false
    }

    func menuWillOpen(_ menu: NSMenu) {
        guard menu === processesMenu else {
            return
        }
        rebuildProcessesMenu()
    }

    func menuDidClose(_ menu: NSMenu) {
        guard menu === processesMenu else {
            return
        }
    }

    private func rebuildProcessesMenu() {
        processesMenu.removeAllItems()

        processesMenu.addItem(headerItem())
        processesMenu.addItem(.separator())

        let topProcesses = processMonitor.topProcesses(limit: 10)
        if topProcesses.isEmpty {
            processesMenu.addItem(processRowItem(name: "No process data", cpuPercent: nil, isDimmed: true))
        } else {
            for process in topProcesses {
                processesMenu.addItem(processRowItem(name: process.name, cpuPercent: process.cpuPercent, isDimmed: false))
            }
        }

        if !processesMenu.items.isEmpty {
            processesMenu.addItem(.separator())
        }

        processesMenu.addItem(
            processRowItem(
                name: "Total",
                cpuPercent: processMonitor.totalCPUPercent(),
                isDimmed: true
            )
        )
        processesMenu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(showPreferencesMenuItemClicked(_:)),
            keyEquivalent: ""
        )
        settingsItem.target = self
        processesMenu.addItem(settingsItem)

        let quitItem = NSMenuItem(
            title: "Quit CPU MenuBar",
            action: #selector(quitAppMenuItemClicked(_:)),
            keyEquivalent: ""
        )
        quitItem.target = self
        processesMenu.addItem(quitItem)
    }

    @objc
    private func showPreferencesMenuItemClicked(_ sender: Any?) {
        guard let button = statusItem.button else {
            return
        }

        if preferencesPopoverController.isShown {
            preferencesPopoverController.close()
        } else {
            preferencesPopoverController.show(relativeTo: button)
        }
    }

    @objc
    private func quitAppMenuItemClicked(_ sender: Any?) {
        NSApplication.shared.terminate(nil)
    }

    private func headerItem() -> NSMenuItem {
        processRowItem(name: "Process", cpuPercent: 0, isDimmed: true, isHeader: true)
    }

    private func processRowItem(name: String, cpuPercent: Double?, isDimmed: Bool, isHeader: Bool = false) -> NSMenuItem {
        let displayedPercent = isHeader ? "% CPU" : (cpuPercent.map(formatCPUPercent) ?? "")
        let title = "\(name)\t\(displayedPercent)"
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.attributedTitle = tableAttributedTitle(
            title,
            isHeader: isHeader,
            isDimmed: isDimmed
        )
        return item
    }

    private func tableAttributedTitle(_ text: String, isHeader: Bool, isDimmed: Bool) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byTruncatingTail
        let tabStop = NSTextTab(textAlignment: .right, location: 250)
        paragraph.tabStops = [tabStop]
        paragraph.defaultTabInterval = 250

        return NSAttributedString(
            string: text,
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: isHeader ? .semibold : .regular),
                .foregroundColor: isDimmed ? NSColor.secondaryLabelColor : NSColor.labelColor,
                .paragraphStyle: paragraph
            ]
        )
    }

    private func formatCPUPercent(_ cpuPercent: Double) -> String {
        if cpuPercent >= 10 {
            return String(format: "%.0f%%", cpuPercent)
        }

        if cpuPercent >= 1 {
            return String(format: "%.1f%%", cpuPercent)
        }

        if cpuPercent >= 0.1 {
            return String(format: "%.2f%%", cpuPercent)
        }

        return String(format: "%.1f%%", cpuPercent)
    }
}
