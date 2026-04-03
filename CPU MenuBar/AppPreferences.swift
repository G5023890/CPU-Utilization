import SwiftUI

@MainActor
final class AppPreferences: ObservableObject {
    private enum Keys {
        static let highCpuColorEnabled = "highCpuColorEnabled"
        static let highCpuThreshold = "highCpuThreshold"
    }

    var onChange: (() -> Void)?

    @Published var highCpuColorEnabled: Bool {
        didSet {
            UserDefaults.standard.set(highCpuColorEnabled, forKey: Keys.highCpuColorEnabled)
            onChange?()
        }
    }

    @Published var highCpuThreshold: Double {
        didSet {
            UserDefaults.standard.set(highCpuThreshold, forKey: Keys.highCpuThreshold)
            onChange?()
        }
    }

    init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            Keys.highCpuColorEnabled: true,
            Keys.highCpuThreshold: 80.0
        ])

        highCpuColorEnabled = defaults.object(forKey: Keys.highCpuColorEnabled) as? Bool ?? true
        highCpuThreshold = defaults.object(forKey: Keys.highCpuThreshold) as? Double ?? 80.0
    }
}
