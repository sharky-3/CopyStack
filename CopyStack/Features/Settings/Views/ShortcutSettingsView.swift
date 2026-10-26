import SwiftUI

struct ShortcutSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    private let panelKeys: [([String], String)] = [
        (["←", "→"], "Move between clips"),
        (["↑", "↓"], "Move in columns and grids"),
        (["↩"], "Paste the selected clip"),
        (["⌘", "1…9"], "Paste a clip by its number"),
        (["space"], "Preview the full clip"),
        (["⌘", "P"], "Pin or unpin a clip"),
        (["⌘", "⌫"], "Delete a clip"),
        (["⇥"], "Switch category"),
        (["esc"], "Clear search, then close")
    ]

    var body: some View {
        SettingsPage(.shortcut) {
            SettingsCard("Open CopyStack") {
                VStack(spacing: 14) {
                    ShortcutRecorder(shortcut: $settings.shortcut)
                        .padding(.top, 14)

                    if let warning = settings.shortcut.warning {
                        Label(warning, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack {
                        Text("Click the box, then press a key combo or a mouse button (middle click, side buttons).")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Reset") {
                            settings.shortcut = Shortcut.standard
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.bottom, 12)
                }
            }

            SettingsCard("Quick picks") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Shortcut.presets, id: \.self) { preset in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    settings.shortcut = preset
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    ForEach(Array(preset.parts.enumerated()), id: \.offset) { _, part in
                                        Keycap(text: part)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(settings.shortcut == preset ? Color.accentColor.opacity(0.22) : Color.primary.opacity(0.06)))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(settings.shortcut == preset ? Color.accentColor : .clear, lineWidth: 1.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 14)
                }
            }

            SettingsCard("Inside the panel") {
                VStack(spacing: 0) {
                    ForEach(Array(panelKeys.enumerated()), id: \.offset) { index, entry in
                        HStack {
                            HStack(spacing: 4) {
                                ForEach(entry.0, id: \.self) { key in
                                    Keycap(text: key)
                                }
                            }
                            Spacer()
                            Text(entry.1)
                                .font(.system(size: 12.5))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                        if index < panelKeys.count - 1 {
                            SettingsDivider(inset: 0)
                        }
                    }
                }
            }
        }
    }
}
