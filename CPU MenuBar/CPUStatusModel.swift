import AppKit
import SwiftUI

@MainActor
final class CPUStatusModel: ObservableObject {
    @Published private(set) var displayText = "--"
    @Published private(set) var textColor = Color.primary

    private let preferences: AppPreferences
    private let cpuMonitor = CPUUsageMonitor()
    private var timer: Timer?

    init(preferences: AppPreferences) {
        self.preferences = preferences
        preferences.onChange = { [weak self] in
            self?.refreshAppearance()
        }
        refreshAppearance()
        start()
    }

    func start() {
        guard timer == nil else {
            return
        }

        cpuMonitor.prime()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshCPUUsage()
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func refreshCPUUsage() {
        guard let usage = cpuMonitor.sampleUsage() else {
            return
        }

        let percent = max(0, min(100, Int((usage * 100).rounded())))
        displayText = "\(percent)"
        refreshAppearance(percent: percent)
    }

    private func refreshAppearance(percent: Int? = nil) {
        guard
            preferences.highCpuColorEnabled,
            let percent,
            percent >= Int(preferences.highCpuThreshold)
        else {
            textColor = .primary
            return
        }

        textColor = .red
    }
}
