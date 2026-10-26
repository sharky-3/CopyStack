import AppKit
import SwiftUI

final class OnboardingWindowController {
    static let shared = OnboardingWindowController()
    private var window: NSWindow?

    func show() {
        if window == nil {
                makeWindow()
        }
        guard let window else { return }
        if !window.isVisible { window.center() }
        WindowPresenter.shared.present(window)
    }

    func showIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "hasOnboarded") else { return }
        show()
    }

    private func makeWindow() {
        let view = OnboardingView { [weak self] in
            UserDefaults.standard.set(true, forKey: "hasOnboarded")
            self?.window?.close()
            self?.window = nil
        }
        let hosting = NSHostingController(rootView: view)
        hosting.sizingOptions = []
        let w = NSWindow(contentViewController: hosting)
        w.styleMask = [.titled, .closable, .fullSizeContentView]
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.isMovableByWindowBackground = true
        w.isReleasedWhenClosed = false
        w.backgroundColor = .windowBackgroundColor
        w.setContentSize(NSSize(width: 620, height: 680))
        window = w
    }
}
