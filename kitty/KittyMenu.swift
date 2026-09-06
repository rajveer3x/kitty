import SwiftUI

struct KittyMenu: View {
    @ObservedObject var cpuMonitor: CPUMonitor
    @ObservedObject var loginItemManager: LoginItemManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kitty").font(.headline)
            LabeledContent("CPU usage") { Text("\(cpuMonitor.usagePercent, format: .number.precision(.fractionLength(1)))%") }
            LabeledContent("Run above") { Text("\(cpuMonitor.threshold, format: .number.precision(.fractionLength(0)))%") }
            Slider(value: $cpuMonitor.threshold, in: 10...100, step: 1).accessibilityLabel("CPU run threshold")
            Toggle("Pause animations", isOn: $cpuMonitor.isAnimationPaused)
            Toggle("Launch Kitty at login", isOn: Binding(
                get: { loginItemManager.isEnabled },
                set: { loginItemManager.setEnabled($0) }
            ))
            if let errorMessage = loginItemManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Open Login Items Settings") { loginItemManager.openLoginItemsSettings() }
            }
            Divider()
            Button("Quit Kitty") { NSApplication.shared.terminate(nil) }.keyboardShortcut("q")
        }
        .padding(14)
        .frame(width: 230)
    }
}
