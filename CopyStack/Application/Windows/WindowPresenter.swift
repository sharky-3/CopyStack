import AppKit

final class WindowPresenter: NSObject {
    static let shared = WindowPresenter()

    private var observed = Set<ObjectIdentifier>()

    func present(_ window: NSWindow) {
        observe(window)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func observe(_ window: NSWindow) {
        let id = ObjectIdentifier(window)
        guard !observed.contains(id) else { return }
        observed.insert(id)
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillClose), name: NSWindow.willCloseNotification, object: window)
    }

    @objc private func windowWillClose(_ note: Notification) {
        DispatchQueue.main.async {
            let anyOpen = NSApp.windows.contains { $0.isVisible && $0.styleMask.contains(.titled) }
            if !anyOpen {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}
