import AppKit
import SwiftUI

final class OnboardingWindowController {
    static let shared = OnboardingWindowController()
    private var window: NSWindow?

    func show() {
        if window == nil {
            makeWindow()
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "hasOnboarded") else { return }
        show()
    }

    private func makeWindow() {
        let view = OnboardingView { [weak self] in
            UserDefaults.standard.set(true, forKey: "hasOnboarded")
            self?.window?.close()
        }
        let hosting = NSHostingController(rootView: view)
        let w = NSWindow(contentViewController: hosting)
        w.styleMask = [.titled, .closable, .fullSizeContentView]
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.isReleasedWhenClosed = false
        window = w
    }
}
