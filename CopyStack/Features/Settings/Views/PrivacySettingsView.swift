import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PrivacySettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        SettingsPage(.privacy) {
            SettingsCard("Sensitive data") {
                SettingsRow(symbol: "key.fill", color: .purple, title: "Skip passwords & secrets", subtitle: "Ignore anything password managers mark as concealed or temporary.") {
                    Toggle("", isOn: $settings.ignoreConcealed)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }

            SettingsCard("Ignored apps") {
                VStack(spacing: 0) {
                    if settings.ignoredApps.isEmpty {
                        Text("Copies from these apps are never recorded. Add a password manager or a banking app.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 14)
                    } else {
                        ForEach(settings.ignoredApps, id: \.self) { bundleID in
                            HStack(spacing: 12) {
                                if let icon = ThumbnailLoader.shared.appIcon(bundleID: bundleID) {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                }
                                Text(ThumbnailLoader.shared.appName(bundleID: bundleID))
                                    .font(.system(size: 13.5, weight: .medium))
                                Spacer()
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        settings.ignoredApps.removeAll { $0 == bundleID }
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 17))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 8)
                            SettingsDivider()
                        }
                    }

                    HStack {
                        Button {
                            addApp()
                        } label: {
                            Label("Add App…", systemImage: "plus")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
            }

            SettingsCard {
                SettingsRow(symbol: "lock.shield.fill", color: .green, title: "Everything stays on your Mac", subtitle: "CopyStack has no accounts and never sends your clipboard anywhere.") {
                    EmptyView()
                }
            }
        }
    }

    private func addApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.prompt = "Ignore"
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            guard let id = Bundle(url: url)?.bundleIdentifier, !settings.ignoredApps.contains(id) else { continue }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                settings.ignoredApps.append(id)
            }
        }
    }
}
