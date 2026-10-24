import SwiftUI
import Combine

struct GeneralSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var manager = ClipboardManager.shared
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var accessibility = PasteHelper.isTrusted

    private let poll = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        SettingsPage(.general) {
            SettingsCard("Startup") {
                SettingsRow(symbol: "power", color: .green, title: "Launch at login", subtitle: "Start CopyStack quietly in the menu bar when you sign in.") {
                    Toggle("", isOn: $launchAtLogin)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                SettingsDivider()
                SettingsRow(symbol: "accessibility", color: .blue, title: "Accessibility access", subtitle: accessibility ? "Granted — CopyStack can paste into any app for you." : "Needed so CopyStack can press ⌘V in the app you were using.") {
                    if accessibility {
                        Label("Granted", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.green)
                    } else {
                        Button("Grant Access") {
                            PasteHelper.requestPermission()
                            PasteHelper.openAccessibilitySettings()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }

            SettingsCard("Pasting") {
                SettingsRow(symbol: "doc.on.clipboard.fill", color: .orange, title: "Paste automatically", subtitle: "Choosing a clip presses ⌘V for you. Turn off to only copy it to the clipboard.") {
                    Toggle("", isOn: $settings.autoPaste)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                SettingsDivider()
                SettingsRow(symbol: "speaker.wave.2.fill", color: .pink, title: "Sound on copy", subtitle: "Play a soft tick whenever something new lands in your stack.") {
                    Toggle("", isOn: $settings.playSounds)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }

            SettingsCard("Menu Bar") {
                SettingsRow(symbol: "number.square.fill", color: .purple, title: "Show clip count", subtitle: "Display how many clips you have inside the menu bar icon.") {
                    Toggle("", isOn: $settings.showCountInMenuBar)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                SettingsDivider()
                SettingsRow(symbol: "pause.circle.fill", color: .gray, title: "Pause monitoring", subtitle: "Stop recording new copies until you turn this off.") {
                    Toggle("", isOn: Binding(get: { !manager.isMonitoring }, set: { paused in
                        if paused {
                            manager.stopMonitoring()
                        } else {
                            manager.startMonitoring()
                        }
                    }))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }
            }
        }
        .onChange(of: launchAtLogin) { _, enabled in LaunchAtLogin.set(enabled: enabled) }
        .onReceive(poll) { _ in accessibility = PasteHelper.isTrusted }
    }
}
