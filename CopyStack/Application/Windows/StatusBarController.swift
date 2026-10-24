import AppKit
import Combine

final class StatusBarController: NSObject {
    static let shared = StatusBarController()

    private var statusItem: NSStatusItem!
    private var bag = Set<AnyCancellable>()
    private var pauseMenuItem: NSMenuItem?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon(count: ClipboardManager.shared.items.count, showCount: AppSettings.shared.showCountInMenuBar)

        Publishers.CombineLatest(ClipboardManager.shared.$items, AppSettings.shared.$showCountInMenuBar)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items, showCount in
                self?.updateIcon(count: items.count, showCount: showCount)
            }
            .store(in: &bag)

        AppSettings.shared.$shortcut
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shortcut in self?.buildMenu(shortcut: shortcut) }
            .store(in: &bag)

        ClipboardManager.shared.$isMonitoring
            .receive(on: DispatchQueue.main)
            .sink { [weak self] monitoring in
                self?.pauseMenuItem?.title = monitoring ? "Pause Monitoring" : "Resume Monitoring"
            }
            .store(in: &bag)

        buildMenu(shortcut: AppSettings.shared.shortcut)
    }

    private func updateIcon(count: Int, showCount: Bool) {
        guard let button = statusItem.button else { return }
        if showCount {
            button.image = Self.badgeImage(count: min(count, 99))
        } else {
            let image = NSImage(systemSymbolName: "square.on.square", accessibilityDescription: "CopyStack")
            image?.isTemplate = true
            button.image = image
        }
    }

    private static func badgeImage(count: Int) -> NSImage {
        let size = NSSize(width: 20, height: 20)
        let image = NSImage(size: size, flipped: false) { _ in
            let rect = NSRect(x: 1, y: 1, width: 18, height: 18)
            let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
            NSColor.labelColor.withAlphaComponent(0.9).setStroke()
            path.lineWidth = 1.4
            path.stroke()

            if count > 0 {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: count > 9 ? 9 : 10, weight: .semibold),
                    .foregroundColor: NSColor.labelColor
                ]
                let text = NSAttributedString(string: "\(count)", attributes: attrs)
                let textSize = text.size()
                text.draw(at: NSPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2))
            }
            return true
        }
        image.isTemplate = false
        return image
    }

    private func buildMenu(shortcut: Shortcut) {
        let menu = NSMenu()

        let showItem = NSMenuItem(title: "Show Copy Stack", action: #selector(showStack), keyEquivalent: shortcut.menuKeyEquivalent ?? "")
        if shortcut.menuKeyEquivalent != nil {
            showItem.keyEquivalentModifierMask = shortcut.modifiers
        }
        showItem.target = self
        menu.addItem(showItem)

        menu.addItem(.separator())

        let pauseItem = NSMenuItem(title: ClipboardManager.shared.isMonitoring ? "Pause Monitoring" : "Resume Monitoring", action: #selector(togglePause), keyEquivalent: "")
        pauseItem.target = self
        menu.addItem(pauseItem)
        pauseMenuItem = pauseItem

        let clearItem = NSMenuItem(title: "Clear Unpinned History", action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(.separator())

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

        let quitItem = NSMenuItem(title: "Quit CopyStack", action: #selector(quit), keyEquivalent: "q")
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
    }

    @objc private func clearHistory() {
        ClipboardManager.shared.clearAll(keepPinned: true)
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func replayOnboarding() {
        OnboardingWindowController.shared.show()
    }

    @objc private func checkForUpdates() {
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
