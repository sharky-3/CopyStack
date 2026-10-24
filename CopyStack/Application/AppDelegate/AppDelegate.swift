import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppSettings.shared.applyTheme()

        _ = ClipboardManager.shared
        StatusBarController.shared.setup()
        HotKeyManager.shared.start()

        OnboardingWindowController.shared.showIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        ClipboardManager.shared.flush()
    }
}
