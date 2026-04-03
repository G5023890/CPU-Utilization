import SwiftUI

struct PreferencesView: View {
    @ObservedObject var preferences: AppPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CPU MenuBar")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Lightweight controls for the menu bar indicator.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Toggle("Highlight high CPU", isOn: $preferences.highCpuColorEnabled)
                .toggleStyle(.switch)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Color threshold")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(preferences.highCpuThreshold))%")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Slider(value: $preferences.highCpuThreshold, in: 50...100, step: 1)
                    .disabled(!preferences.highCpuColorEnabled)
            }
            .opacity(preferences.highCpuColorEnabled ? 1 : 0.5)

            Text("The menu bar stays numeric-only. Color changes are optional.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 280)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }
}
