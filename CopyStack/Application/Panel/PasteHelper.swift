import AppKit
import ApplicationServices

enum PasteHelper {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func requestPermission() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    static func restoreFocus(to target: NSRunningApplication?) {
        guard let target else { return }
        NSApp.yieldActivation(to: target)
        target.activate()
    }

    static func paste(into target: NSRunningApplication?) {
        restoreFocus(to: target)
        guard isTrusted else {
            requestPermission()
            return
        }
        waitUntilReady(target: target, attempt: 0) {
            postCommandV()
        }
    }

    private static func waitUntilReady(target: NSRunningApplication?, attempt: Int, then action: @escaping () -> Void) {
        let frontIsTarget = target == nil || NSWorkspace.shared.frontmostApplication?.processIdentifier == target?.processIdentifier
        let strayModifiers = !NSEvent.modifierFlags.intersection([.shift, .option, .control]).isEmpty
        if (frontIsTarget && !strayModifiers) || attempt >= 30 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                action()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                waitUntilReady(target: target, attempt: attempt + 1, then: action)
            }
        }
    }

    private static func postCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        source?.setLocalEventsFilterDuringSuppressionState([.permitLocalMouseEvents, .permitSystemDefinedEvents], state: .eventSuppressionStateSuppressionInterval)
        let down = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cgSessionEventTap)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.012) {
            up?.post(tap: .cgSessionEventTap)
        }
    }
}
