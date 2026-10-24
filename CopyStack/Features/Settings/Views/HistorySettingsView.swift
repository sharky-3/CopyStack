import SwiftUI

struct HistorySettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var manager = ClipboardManager.shared
    @State private var diskBytes = 0
    @State private var confirmClear = false

    var body: some View {
        SettingsPage(.history) {
            SettingsCard("Stack size") {
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(settings.maxItems)")
                            .font(.system(size: 54, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: settings.maxItems)
                        Text("clips")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.top, 10)

                    Slider(value: Binding(get: { Double(settings.maxItems) }, set: { settings.maxItems = Int($0) }), in: 5...50, step: 1)

                    HStack {
                        Text("5")
                        Spacer()
                        Text("Pinned clips never count toward the limit.")
                        Spacer()
                        Text("50")
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)
                }
            }

            SettingsCard("Storage") {
                SettingsRow(symbol: "externaldrive.fill", color: .green, title: "Remember history", subtitle: "Keep your clips after quitting or restarting. Everything stays on this Mac.") {
                    Toggle("", isOn: $settings.saveHistory)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                SettingsDivider()
                SettingsRow(symbol: "photo.fill", color: .pink, title: "Largest image to keep", subtitle: "Bigger images are skipped so CopyStack stays fast.") {
                    Picker("", selection: $settings.maxImageMB) {
                        Text("10 MB").tag(10)
                        Text("25 MB").tag(25)
                        Text("50 MB").tag(50)
                        Text("100 MB").tag(100)
                        Text("250 MB").tag(250)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 110)
                }
            }

            SettingsCard("Right now") {
                SettingsRow(symbol: "square.stack.3d.up.fill", color: .blue, title: "\(manager.items.count) clips stored", subtitle: "\(ByteCountFormatter.string(fromByteCount: Int64(diskBytes), countStyle: .file)) of images on disk") {
                    Button("Clear History…", role: .destructive) {
                        confirmClear = true
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .task { await refreshUsage() }
        .onChange(of: manager.items.count) { _, _ in
            Task { await refreshUsage() }
        }
        .confirmationDialog("Clear your clipboard history?", isPresented: $confirmClear) {
            Button("Clear Unpinned", role: .destructive) {
                manager.clearAll(keepPinned: true)
            }
            Button("Clear Everything", role: .destructive) {
                manager.clearAll(keepPinned: false)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func refreshUsage() async {
        let bytes = await Task.detached(priority: .utility) {
            ClipboardStore.imagesDiskUsage()
        }.value
        diskBytes = bytes
    }
}
