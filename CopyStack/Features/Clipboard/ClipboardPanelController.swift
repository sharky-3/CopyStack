import AppKit
import SwiftUI

final class ClipboardPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

final class ClipboardPanelController: NSObject {
    static let shared = ClipboardPanelController()

    private var panel: ClipboardPanel?
    private var keyMonitor: Any?
    private var shownAt = Date.distantPast
    private var closeToken = 0
    private(set) var previousApp: NSRunningApplication?

    var isVisible: Bool { panel?.isVisible ?? false }

    func toggle() {
        if isVisible {
            close()
        } else {
            show()
        }
    }

    func show() {
        if let front = NSWorkspace.shared.frontmostApplication, front.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousApp = front
        }
        if panel == nil { makePanel() }
        guard let panel else { return }

        closeToken += 1
        shownAt = Date()

        let vm = PanelViewModel.shared
        vm.presented = false
        vm.prepareForShow()

        layoutPanel()
        panel.alphaValue = 1
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        installKeyMonitor()

        DispatchQueue.main.async {
            vm.presented = true
            panel.invalidateShadow()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            panel.invalidateShadow()
        }
    }

    func close() {
        guard let panel, panel.isVisible else { return }
        removeKeyMonitor()
        closeToken += 1
        let token = closeToken
        PanelViewModel.shared.presented = false
        let delay = AppSettings.shared.panelPosition == .notch ? 0.45 : 0.16
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.closeToken == token else { return }
            panel.orderOut(nil)
        }
    }

    private func makePanel() {
        let hosting = NSHostingView(rootView: ClipboardPanelView(onClose: { [weak self] in self?.close() }))
        hosting.sizingOptions = []

        let p = ClipboardPanel(contentRect: NSRect(x: 0, y: 0, width: 800, height: 400), styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView], backing: .buffered, defer: false)
        p.isFloatingPanel = true
        p.level = .floating
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.hidesOnDeactivate = false
        p.contentView = hosting

        NotificationCenter.default.addObserver(self, selector: #selector(panelDidResignKey), name: NSWindow.didResignKeyNotification, object: p)

        panel = p
    }

    @objc private func panelDidResignKey() {
        guard AppSettings.shared.closeOnFocusLoss else { return }
        guard Date().timeIntervalSince(shownAt) > 0.4 else { return }
        close()
    }

    private var targetScreen: NSScreen? {
        if AppSettings.shared.screenTarget == .mouse {
            let mouse = NSEvent.mouseLocation
            if let hit = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) {
                return hit
            }
        }
        return NSScreen.screens.first ?? NSScreen.main
    }

    private func layoutPanel() {
        guard let panel, let screen = targetScreen else { return }
        let settings = AppSettings.shared
        let isNotch = settings.panelPosition == .notch
        let frame = isNotch ? screen.frame : screen.visibleFrame
        let margin = CGFloat(settings.edgeMargin)
        let rawInset = isNotch ? screen.safeAreaInsets.top : 0
        let inset: CGFloat = isNotch ? (rawInset > 0 ? rawInset : 28) : 0
        var notchWidth: CGFloat = 190
        if isNotch, let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            notchWidth = screen.frame.width - left.width - right.width
        }
        PanelViewModel.shared.notchInset = inset
        PanelViewModel.shared.notchWidth = notchWidth
        panel.hasShadow = !isNotch
        panel.level = isNotch ? NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 1) : .floating
        let size = PanelGeometry.size(position: settings.panelPosition, cardSize: settings.cardSize, in: frame, margin: margin, topInset: inset)
        let origin = PanelGeometry.origin(position: settings.panelPosition, size: size, in: frame, margin: margin)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event -> NSEvent? in
            guard let self, let panel = self.panel, panel.isVisible else { return event }
            return self.handle(event)
        }
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        let vm = PanelViewModel.shared
        let layout = AppSettings.shared.panelPosition.layout
        let command = event.modifierFlags.contains(.command)

        switch event.keyCode {
        case 123:
            guard layout != .column else { return event }
            vm.moveSelection(by: -1)
            return nil
        case 124:
            guard layout != .column else { return event }
            vm.moveSelection(by: 1)
            return nil
        case 126:
            switch layout {
            case .strip: return event
            case .notch: return nil
            case .column: vm.moveSelection(by: -1)
            case .grid: vm.moveSelection(by: -vm.gridColumns)
            }
            return nil
        case 125:
            switch layout {
            case .strip: return event
            case .notch: return nil
            case .column: vm.moveSelection(by: 1)
            case .grid: vm.moveSelection(by: vm.gridColumns)
            }
            return nil
        case 48:
            guard layout != .notch else { return nil }
            vm.cycleCategory(by: event.modifierFlags.contains(.shift) ? -1 : 1)
            return nil
        case 36, 76:
            if let editor = panel?.firstResponder as? NSTextView, editor.hasMarkedText() { return event }
            vm.pasteSelected()
            return nil
        case 49:
            guard layout != .notch else { return nil }
            guard vm.searchText.isEmpty else { return event }
            vm.togglePreview()
            return nil
        case 35 where command:
            vm.togglePinSelected()
            return nil
        case 51 where command:
            vm.deleteSelected()
            return nil
        case 53:
            if vm.isPreviewing {
                vm.isPreviewing = false
            } else if !vm.searchText.isEmpty {
                vm.searchText = ""
            } else {
                close()
            }
            return nil
        default:
            if command, let chars = event.charactersIgnoringModifiers, let n = Int(chars), (1...9).contains(n), vm.filteredItems.indices.contains(n - 1) {
                ClipboardManager.shared.paste(vm.filteredItems[n - 1])
                return nil
            }
            return layout == .notch ? nil : event
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        keyMonitor = nil
    }
}
