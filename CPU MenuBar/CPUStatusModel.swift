import Foundation
import SwiftUI

@MainActor
final class CPUIndicatorViewModel: NSObject, ObservableObject {
    @Published private(set) var displayText = "--"
    @Published private(set) var progress: Double = 0
    @Published private(set) var trackOpacity: Double = 0.24
    @Published private(set) var activeOpacity: Double = 0.90
    @Published private(set) var textOpacity: Double = 0.94

    private let usageProvider: CPUUsageProviding
    private var timer: Timer?
    private var smoothedPercent: Double = 0
    private var hasPrimedDisplay = false
    private var sustainedHighLoadStartedAt: Date?

    init(usageProvider: CPUUsageProviding = MachCPUUsageProvider()) {
        self.usageProvider = usageProvider
    }

    func start() {
        guard timer == nil else {
            return
        }

        usageProvider.prime()
        refreshCPUUsage()

        let timer = Timer(
            timeInterval: 1,
            target: self,
            selector: #selector(handleTimerTick),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    @objc
    private func handleTimerTick() {
        refreshCPUUsage()
    }

    private func refreshCPUUsage() {
        guard let usage = usageProvider.sampleUsage() else {
            return
        }

        let rawPercent = max(0, min(100, usage * 100))
        updateSustainedHighLoadState(rawPercent: rawPercent)
        let sustainedHighLoad = isSustainedHighLoad

        if hasPrimedDisplay {
            smoothedPercent = (smoothedPercent * 0.7) + (rawPercent * 0.3)
        } else {
            smoothedPercent = rawPercent
            hasPrimedDisplay = true
        }

        let clampedPercent = max(0, min(100, Int(smoothedPercent.rounded())))

        displayText = "\(clampedPercent)"
        progress = smoothedPercent / 100
        trackOpacity = sustainedHighLoad ? 0.28 : 0.24
        activeOpacity = sustainedHighLoad ? 0.97 : 0.90
        textOpacity = sustainedHighLoad ? 1.0 : 0.94
    }

    private func updateSustainedHighLoadState(rawPercent: Double) {
        let now = Date()

        if rawPercent > 90 {
            if sustainedHighLoadStartedAt == nil {
                sustainedHighLoadStartedAt = now
            }
        } else {
            sustainedHighLoadStartedAt = nil
        }
    }

    private var isSustainedHighLoad: Bool {
        guard let sustainedHighLoadStartedAt else {
            return false
        }

        return Date().timeIntervalSince(sustainedHighLoadStartedAt) >= 5
    }

    var displayFontSize: CGFloat {
        guard let displayValue = Int(displayText) else {
            return 10.2
        }

        switch displayValue {
        case 100:
            return 8.6
        case 10...99:
            return 9.5
        default:
            return 10.2
        }
    }
}
