import SwiftUI

struct PanelSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        SettingsPage(.panel) {
            SettingsCard("Position") {
                VStack(spacing: 16) {
                    PositionPreview(position: settings.panelPosition)
                        .frame(maxWidth: 420)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)

                    PositionPicker(selection: $settings.panelPosition)

                    Text(settings.panelPosition.summary)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: settings.panelPosition)
                        .padding(.bottom, 12)
                }
            }

            SettingsCard("Appearance") {
                SettingsRow(symbol: "circle.lefthalf.filled", color: .gray, title: "Theme", subtitle: "Plain light or dark for the panel and every window.") {
                    Picker("", selection: $settings.theme) {
                        ForEach(AppearanceTheme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 140)
                }
                SettingsDivider()
                SettingsRow(symbol: "rectangle.grid.2x2.fill", color: .blue, title: "Card size", subtitle: "Bigger cards reveal more of every text you copied.") {
                    Picker("", selection: $settings.cardSize) {
                        ForEach(CardSize.allCases) { size in
                            Text(size.title).tag(size)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 140)
                }
                SettingsDivider()
                SettingsRow(symbol: "arrow.up.left.and.arrow.down.right", color: .teal, title: "Edge margin", subtitle: "Space between the panel and the edge of your screen.") {
                    HStack(spacing: 10) {
                        Slider(value: $settings.edgeMargin, in: 0...40, step: 2)
                            .frame(width: 150)
                        Text("\(Int(settings.edgeMargin)) pt")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 42, alignment: .trailing)
                    }
                }
            }

            SettingsCard("Behavior") {
                SettingsRow(symbol: "display", color: .indigo, title: "Open on", subtitle: "Which display shows the panel when you have more than one.") {
                    Picker("", selection: $settings.screenTarget) {
                        ForEach(ScreenTarget.allCases) { target in
                            Text(target.title).tag(target)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 170)
                }
                SettingsDivider()
                SettingsRow(symbol: "hand.tap.fill", color: .orange, title: "Close when I click away", subtitle: "Dismiss the panel as soon as it loses focus.") {
                    Toggle("", isOn: $settings.closeOnFocusLoss)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }

            Button {
                ClipboardPanelController.shared.show()
            } label: {
                Label("Preview the panel now", systemImage: "play.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}
