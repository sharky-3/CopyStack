import SwiftUI
import Combine

struct OnboardingView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var page = 0
    @State private var launchAtLogin = false
    @State private var accessibility = PasteHelper.isTrusted

    var onFinish: () -> Void

    private let poll = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let pageCount = 3

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 0) {
                ZStack {
                    switch page {
                    case 0: welcomePage
                    case 1: personalizePage
                    default: finishPage
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                .id(page)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                dots
                    .padding(.bottom, 26)
            }
            .padding(.top, 30)
        }
        .frame(width: 620, height: 680)
        .ignoresSafeArea()
        .onReceive(poll) { _ in accessibility = PasteHelper.isTrusted }
    }

    private var backdrop: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

        }
    }

    private var dots: some View {
        HStack(spacing: 7) {
            ForEach(0..<pageCount, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Color.primary : Color.primary.opacity(0.25))
                    .frame(width: i == page ? 20 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: page)
    }

    private func go(_ target: Int) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
            page = target
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 22) {
            Spacer()

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)
                                .revealPop(delay: 0.05)

            VStack(spacing: 10) {
                Text("Welcome to CopyStack")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .revealUp(delay: 0.12)
                Text("Copy several things, then choose what to paste. Your latest copies live in a fast, private stack that never leaves your Mac.")
                    .font(.system(size: 14.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
                    .revealUp(delay: 0.2)
            }

            HStack(spacing: 6) {
                ForEach(Array(settings.shortcut.parts.enumerated()), id: \.offset) { _, part in
                    Keycap(text: part, large: true)
                }
                Text("opens it from anywhere")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 6)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Capsule().fill(.primary.opacity(0.07)))
            .revealUp(delay: 0.3)

            Spacer()

            Button {
                go(1)
            } label: {
                Text("Continue")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 180)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
            .revealUp(delay: 0.4)
            .padding(.bottom, 24)
        }
    }

    private var personalizePage: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text("Make it yours")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text("Pick where the stack appears and how you open it. You can change both anytime in Settings.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
            }
            .padding(.top, 20)

            PositionPreview(position: settings.panelPosition)
                .frame(width: 380)

            PositionPicker(selection: $settings.panelPosition)
                .padding(.horizontal, 50)

            VStack(spacing: 6) {
                ShortcutRecorder(shortcut: $settings.shortcut)
                Text("Click the box and press any combo or mouse button.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 50)

            Spacer(minLength: 0)

            HStack(spacing: 14) {
                Button("Back") { go(0) }
                    .buttonStyle(.bordered)
                Button {
                    go(2)
                } label: {
                    Text("Continue")
                        .frame(width: 120)
                }
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
            .padding(.bottom, 20)
        }
    }

    private var finishPage: some View {
        VStack(spacing: 22) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.18))
                    .frame(width: 104, height: 104)
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.green)
            }
            .revealPop(delay: 0.05)

            VStack(spacing: 10) {
                Text("You're all set")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("CopyStack lives in your menu bar. Copy freely, then press \(settings.shortcut.display) whenever you're ready to paste.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
            }

            VStack(spacing: 0) {
                SettingsRow(symbol: "accessibility", color: .blue, title: "Allow pasting", subtitle: accessibility ? "Accessibility access granted." : "Lets CopyStack press ⌘V in the app you were using.") {
                    if accessibility {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 18))
                    } else {
                        Button("Grant") {
                            PasteHelper.requestPermission()
                            PasteHelper.openAccessibilitySettings()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                SettingsDivider()
                SettingsRow(symbol: "power", color: .green, title: "Launch at login", subtitle: "Always ready in the menu bar.") {
                    Toggle("", isOn: $launchAtLogin)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.primary.opacity(0.06)))
            .padding(.horizontal, 50)

            Spacer()

            HStack(spacing: 14) {
                Button("Back") { go(1) }
                    .buttonStyle(.bordered)
                Button {
                    LaunchAtLogin.set(enabled: launchAtLogin)
                    onFinish()
                } label: {
                    Text("Finish")
                        .frame(width: 120)
                }
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
            .padding(.bottom, 20)
        }
    }
}
