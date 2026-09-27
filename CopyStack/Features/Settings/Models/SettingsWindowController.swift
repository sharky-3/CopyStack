import AppKit
import SwiftUI

final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func show() {
        if window == nil {
            let vc = NSHostingController(rootView: Text("Settings coming soon").padding(40))
            let w = NSWindow(contentViewController: vc)
            w.styleMask = [.titled, .closable]
            w.title = "CopyStack Settings"
            w.isReleasedWhenClosed = false
            window = w
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
