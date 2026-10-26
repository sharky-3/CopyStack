import SwiftUI
import AppKit
import Combine

final class ShortcutRecorderModel: ObservableObject {
    @Published var isRecording = false
    @Published var liveParts: [String] = []
    @Published var hint: String?

    private var monitor: Any?

    func start(onCapture: @escaping (Shortcut) -> Void) {
        stop()
        isRecording = true
        hint = nil
        HotKeyManager.shared.suspend()
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged, .otherMouseDown]) { [weak self] event in
            guard let self else { return event }
            return self.handle(event, onCapture: onCapture)
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
        liveParts = []
        HotKeyManager.shared.resume()
    }

    private func handle(_ event: NSEvent, onCapture: (Shortcut) -> Void) -> NSEvent? {
        let mods = event.modifierFlags.intersection(Shortcut.allowedMask)

        switch event.type {
        case .flagsChanged:
            liveParts = Shortcut.modifierSymbols(mods)
            return nil
        case .keyDown:
            if event.keyCode == 53 {
                stop()
                return nil
            }
            let isFunction = Shortcut.functionKeyCodes.contains(UInt32(event.keyCode))
            if mods.isEmpty && !isFunction {
                hint = "Hold ⌘, ⌃, ⌥ or ⇧ together with the key."
                return nil
            }
            let shortcut = Shortcut(kind: .key, keyCode: UInt32(event.keyCode), keyLabel: Shortcut.label(for: event), mouseButton: 2, modifierBits: mods.rawValue)
            onCapture(shortcut)
            stop()
            return nil
        case .otherMouseDown:
            let shortcut = Shortcut(kind: .mouse, keyCode: 0, keyLabel: "", mouseButton: event.buttonNumber, modifierBits: mods.rawValue)
            onCapture(shortcut)
            stop()
            return nil
        default:
            return event
        }
    }
}

struct ShortcutRecorder: View {
    @Binding var shortcut: Shortcut
    @StateObject private var model = ShortcutRecorderModel()

    var body: some View {
        VStack(spacing: 8) {
            Button {
                if model.isRecording {
                    model.stop()
                } else {
                    model.start { shortcut = $0 }
                }
            } label: {
                HStack(spacing: 8) {
                    if model.isRecording {
                        if model.liveParts.isEmpty {
                            Text("Press a key combo or click a mouse button…")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.accentColor)
                        } else {
                            ForEach(model.liveParts, id: \.self) { part in
                                Keycap(text: part, large: true)
                            }
                        }
                    } else {
                        ForEach(Array(shortcut.parts.enumerated()), id: \.offset) { _, part in
                            Keycap(text: part, large: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(model.isRecording ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(model.isRecording ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: model.isRecording ? 2 : 1))
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: model.isRecording)

            if let hint = model.hint {
                Text(hint)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.orange)
            }
        }
        .onDisappear { model.stop() }
    }
}
