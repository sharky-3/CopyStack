import AppKit
import SwiftUI

final class ClipboardPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class ClipboardPanelController {
    static let shared = ClipboardPanelController()

    private var panel: ClipboardPanel?
    private var keyMonitor: Any?

    private(set) var previousApp: NSRunningApplication?

    func toggle() {
        if let panel, panel.isVisible {
            close()
        } else {
            show()
        }
    }

    func show() {
        previousApp = NSWorkspace.shared.frontmostApplication
        if panel == nil {
            makePanel()
        }
        positionOnScreen()
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        installKeyMonitor()
    }

    func close() {
        panel?.orderOut(nil)
        removeKeyMonitor()
    }

    private func makePanel() {
        let contentView = ClipboardPanelView(onClose: { [weak self] in self?.close() })
        let hosting = NSHostingView(rootView: contentView)

        let p = ClipboardPanel(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 560),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        p.isFloatingPanel = true
        p.level = .floating
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.hidesOnDeactivate = false
        p.contentView = hosting
        panel = p
    }

    private func positionOnScreen() {
        guard let panel, let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        let size = panel.frame.size
        let origin = NSPoint(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2)
        panel.setFrameOrigin(origin)
    }

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event -> NSEvent? in
            guard let self, let panel = self.panel, panel.isVisible else { return event }
            let vm = PanelViewModel.shared

            switch event.keyCode {
            case 126: vm.moveSelection(by: -1); return nil
            case 125: vm.moveSelection(by: 1); return nil
            case 123: vm.cycleCategory(by: -1); return nil
            case 124: vm.cycleCategory(by: 1); return nil
            case 36, 76: vm.pasteSelected(); return nil
            case 51:
                if event.modifierFlags.contains(.command) {
                    vm.deleteSelected()
                    return nil
                }
                return event
            case 53:  self.close(); return nil
            default:
               
                if event.modifierFlags.contains(.command),
                   let chars = event.charactersIgnoringModifiers,
                   let n = Int(chars), (1...9).contains(n),
                   vm.filteredItems.indices.contains(n - 1) {
                    ClipboardManager.shared.paste(vm.filteredItems[n - 1])
                    return nil
                }
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let m = keyMonitor { NSEvent.removeMonitor(m) }
        keyMonitor = nil
    }
}
