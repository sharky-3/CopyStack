import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        StatusBarController.shared.setup()
        HotKeyManager.shared.start()
        PasteHelper.ensureAccessibilityPermission()

        if !UserDefaults.standard.bool(forKey: "hasOnboarded") {
            showOnboarding()
        }
    }

    private func showOnboarding() {
        let view = OnboardingView { [weak self] in
            UserDefaults.standard.set(true, forKey: "hasOnboarded")
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
        }
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }
}
