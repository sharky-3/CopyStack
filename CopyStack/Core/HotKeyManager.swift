import AppKit

final class HotKeyManager {
    static let shared = HotKeyManager()

    private var globalMonitor: Any?
    private var localMonitor: Any?

    func start() {
        let handleEvent: (NSEvent) -> Void = { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard flags == [.command, .shift] else { return }
            guard event.keyCode == 126 || event.keyCode == 9 else { return }
            DispatchQueue.main.async {
                ClipboardPanelController.shared.toggle()
            }
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: handleEvent)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleEvent(event)
            return event
        }
    }

    func stop() {
        if let m = globalMonitor { NSEvent.removeMonitor(m) }
        if let m = localMonitor { NSEvent.removeMonitor(m) }
        globalMonitor = nil
        localMonitor = nil
    }
}
