import SwiftUI

struct OnboardingView: View {
    @State private var page = 0
    @State private var launchAtLogin = false
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "square.on.square")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .foregroundStyle(.blue)

            if page == 0 {
                welcomePage
            } else {
                finishPage
            }

            Spacer()

            HStack(spacing: 6) {
                ForEach(0..<2, id: \.self) { i in
                    Circle()
                        .fill(i == page ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 24)
        }
        .frame(width: 460, height: 480)
        .background(.regularMaterial)
    }

    private var welcomePage: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Welcome to CopyStack").font(.title.bold())
                Text("Copy several things, then choose what to paste. CopyStack keeps your latest copies in a fast, private stack — everything stays on your Mac.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 40)
            }

            HStack {
                Text("⌘⇧↑")
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(.quaternaryLabelColor)))
                Text("(or ⌘⇧V) opens your copy stack from anywhere").foregroundStyle(.secondary)
            }

            Button("Continue") { page = 1 }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }

    private var finishPage: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("You're All Set").font(.title.bold())
                Text("CopyCat lives in your menu bar. Copy freely — press ⌘⇧V whenever you're ready to paste.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 40)
            }

            Toggle("Launch CopyCat at login", isOn: $launchAtLogin)
                .toggleStyle(.checkbox)

            HStack(spacing: 16) {
                Button("Back") { page = 0 }
                Button("Finish") {
                    LaunchAtLogin.set(enabled: launchAtLogin)
                    onFinish()
                }
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
        }
    }
}
