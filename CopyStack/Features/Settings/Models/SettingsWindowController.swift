import AppKit
import SwiftUI

final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func show() {
        if window == nil {
            let hosting = NSHostingView(rootView: SettingsView())
            hosting.sizingOptions = []
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 640), styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView], backing: .buffered, defer: false)
            w.contentView = hosting
            w.titlebarAppearsTransparent = true
            w.titleVisibility = .hidden
            w.isReleasedWhenClosed = false
            w.isOpaque = true
            w.backgroundColor = .windowBackgroundColor
            w.contentMinSize = NSSize(width: 900, height: 640)
            w.contentMaxSize = NSSize(width: 900, height: 640)
            w.setContentSize(NSSize(width: 900, height: 640))
            window = w
        }
        guard let window else { return }
        if !window.isVisible { window.center() }
        WindowPresenter.shared.present(window)
    }
}
