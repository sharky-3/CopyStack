import AppKit
import SwiftUI

final class ClipboardPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

enum PanelPosition {
    case center, top, bottom, left, right
    case topLeft, topCenter, topRight
    case bottomLeft, bottomCenter, bottomRight
    case centerLeft, centerRight
}

final class ClipboardPanelController {

    static let shared = ClipboardPanelController()

    private var panel: ClipboardPanel?
    private var keyMonitor: Any?
    private(set) var previousApp: NSRunningApplication?

    private var panelView: ClipboardPanelBottomView?

    func toggle() {
        if let panel, panel.isVisible {
            close()
        } else {
            show()
        }
    }

    func show() {
        previousApp = NSWorkspace.shared.frontmostApplication
        if panel == nil { makePanel() }
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
        let contentView = ClipboardPanelBottomView(
            onClose: { [weak self] in self?.close() }
        )
        panelView = contentView

        let hosting = NSHostingView(rootView: contentView)
        let p = ClipboardPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: contentView.panelWidth,
                height: contentView.panelHeight
            ),
            styleMask: [
                .borderless,
                .nonactivatingPanel,
                .fullSizeContentView
            ],
            backing: .buffered,
            defer: false
        )

        p.isFloatingPanel = true
        p.level = .floating
        p.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.hidesOnDeactivate = false
        p.contentView = hosting

        panel = p
    }

    private var targetScreen: NSScreen? {
        return NSScreen.screens.first ?? NSScreen.main
    }

    private func positionOnScreen() {
        guard
            let panel,
            let panelView,
            let screen = targetScreen
        else {
            return
        }

        let frame = screen.visibleFrame
        
        let panelWidth = screen.visibleFrame.width
        let panelHeight = panelView.panelHeight
        
        let newSize = NSSize(width: panelWidth, height: panelHeight)
        panel.setContentSize(newSize)

        let padding = panelView.edgePadding
        let origin: NSPoint

        switch panelView.position {
        case .center:
            origin = NSPoint(
                x: frame.midX - newSize.width / 2,
                y: frame.midY - newSize.height / 2
            )

        case .top, .topCenter:
            origin = NSPoint(
                x: frame.midX - newSize.width / 2,
                y: frame.maxY - newSize.height - padding
            )

        case .bottom, .bottomCenter:
            origin = NSPoint(
                x: frame.midX - newSize.width / 2,
                y: frame.minY + padding
            )

        case .left, .centerLeft:
            origin = NSPoint(
                x: frame.minX + padding,
                y: frame.midY - newSize.height / 2
            )

        case .right, .centerRight:
            origin = NSPoint(
                x: frame.maxX - newSize.width - padding,
                y: frame.midY - newSize.height / 2
            )

        case .topLeft:
            origin = NSPoint(
                x: frame.minX + padding,
                y: frame.maxY - newSize.height - padding
            )

        case .topRight:
            origin = NSPoint(
                x: frame.maxX - newSize.width - padding,
                y: frame.maxY - newSize.height - padding
            )

        case .bottomLeft:
            origin = NSPoint(
                x: frame.minX + padding,
                y: frame.minY + padding
            )

        case .bottomRight:
            origin = NSPoint(
                x: frame.maxX - newSize.width - padding,
                y: frame.minY + padding
            )
        }

        panel.setFrameOrigin(origin)
    }

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event -> NSEvent? in
            guard let self, let panel = self.panel, panel.isVisible else {
                return event
            }
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

            case 53:
                self.close()
                return nil

            default:
                if event.modifierFlags.contains(.command),
                   let chars = event.charactersIgnoringModifiers,
                   let n = Int(chars),
                   (1...9).contains(n),
                   vm.filteredItems.indices.contains(n - 1) {

                    ClipboardManager.shared.paste(vm.filteredItems[n - 1])
                    return nil
                }
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let m = keyMonitor {
            NSEvent.removeMonitor(m)
        }
        keyMonitor = nil
    }
}
