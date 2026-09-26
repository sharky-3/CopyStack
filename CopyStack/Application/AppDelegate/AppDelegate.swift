import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        StatusBarController.shared.setup()
        HotKeyManager.shared.start()
        PasteHelper.ensureAccessibilityPermission()

        OnboardingWindowController.shared.show()
    }
}
