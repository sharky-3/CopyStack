import AppKit
import Combine

final class StatusBarController: NSObject {
    static let shared = StatusBarController()

    private var statusItem: NSStatusItem!
    private var cancellable: AnyCancellable?
    private var pauseMenuItem: NSMenuItem!

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon(count: ClipboardManager.shared.items.count)

        cancellable = ClipboardManager.shared.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.updateIcon(count: items.count)
            }

        buildMenu()
    }

    private func updateIcon(count: Int) {
        statusItem.button?.image = Self.badgeImage(count: min(count, 9))
    }

    private static func badgeImage(count: Int) -> NSImage {
        let size = NSSize(width: 20, height: 20)
        let image = NSImage(size: size)
        image.lockFocus()

        let rect = NSRect(x: 1, y: 1, width: 18, height: 18)
        let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
        NSColor.labelColor.withAlphaComponent(0.9).setStroke()
        path.lineWidth = 1.4
        path.stroke()

        if count > 0 {
            let text = "\(count)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: NSColor.labelColor
            ]
            let str = NSAttributedString(string: text, attributes: attrs)
            let strSize = str.size()
            str.draw(at: NSPoint(x: (size.width - strSize.width) / 2, y: (size.height - strSize.height) / 2))
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private func buildMenu() {
        let menu = NSMenu()

        let showItem = NSMenuItem(title: "Show Copy Stack", action: #selector(showStack), keyEquivalent: "v")
        showItem.keyEquivalentModifierMask = [.command, .shift]
        showItem.target = self
        menu.addItem(showItem)

        menu.addItem(.separator())

        let pauseItem = NSMenuItem(title: "Pause", action: #selector(togglePause), keyEquivalent: "")
        pauseItem.target = self
        menu.addItem(pauseItem)
        pauseMenuItem = pauseItem

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let replayItem = NSMenuItem(title: "Replay Onboarding…", action: #selector(replayOnboarding), keyEquivalent: "")
        replayItem.target = self
        menu.addItem(replayItem)

        let updateItem = NSMenuItem(title: "Check for Updates…", action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit CopyCat", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func showStack() {
        ClipboardPanelController.shared.show()
    }

    @objc private func togglePause() {
        if ClipboardManager.shared.isMonitoring {
            ClipboardManager.shared.stopMonitoring()
        } else {
            ClipboardManager.shared.startMonitoring()
        }
        pauseMenuItem.title = ClipboardManager.shared.isMonitoring ? "Pause" : "Resume"
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func replayOnboarding() {
        OnboardingWindowController.shared.show()
    }

    @objc private func checkForUpdates() {
        //
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
