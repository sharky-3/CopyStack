import AppKit

final class WindowPresenter {
    static let shared = WindowPresenter()

    func present(_ window: NSWindow) {
        window.level = .floating
        window.collectionBehavior.insert(.moveToActiveSpace)
        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
    }
}
