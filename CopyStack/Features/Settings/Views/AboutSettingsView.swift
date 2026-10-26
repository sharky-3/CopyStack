import SwiftUI

struct AboutSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var confirmReset = false

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        SettingsPage(.about) {
            VStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 112, height: 112)
                Text("CopyStack")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text(version)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text("Copy several things, then choose what to paste.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)

            SettingsCard("Maintenance") {
                SettingsRow(symbol: "sparkles", color: .blue, title: "Replay onboarding", subtitle: "Walk through the welcome flow again.") {
                    Button("Replay") {
                        OnboardingWindowController.shared.show()
                    }
                    .buttonStyle(.bordered)
                }
                SettingsDivider()
                SettingsRow(symbol: "arrow.counterclockwise", color: .red, title: "Reset all settings", subtitle: "Restore every option to its default. Your history is kept.") {
                    Button("Reset…", role: .destructive) {
                        confirmReset = true
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .confirmationDialog("Reset all settings to defaults?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) {
                settings.resetToDefaults()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
