import AppKit
import Carbon.HIToolbox
import Combine

extension Notification.Name {
    nonisolated static let copyStackHotKeyPressed = Notification.Name("copyStackHotKeyPressed")
}

private nonisolated func carbonHotKeyHandler(_ call: EventHandlerCallRef?, _ event: EventRef?, _ userData: UnsafeMutableRawPointer?) -> OSStatus {
    DispatchQueue.main.async {
        NotificationCenter.default.post(name: .copyStackHotKeyPressed, object: nil)
    }
    return noErr
}

final class HotKeyManager: NSObject {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var globalMouse: Any?
    private var localMouse: Any?
    private var cancellable: AnyCancellable?
    private var suspended = false

    func start() {
        installHandlerIfNeeded()
        NotificationCenter.default.addObserver(self, selector: #selector(hotKeyPressed), name: .copyStackHotKeyPressed, object: nil)
        register(AppSettings.shared.shortcut)
        cancellable = AppSettings.shared.$shortcut
            .removeDuplicates()
            .sink { [weak self] shortcut in self?.register(shortcut) }
    }

    func stop() {
        unregister()
        cancellable = nil
        NotificationCenter.default.removeObserver(self)
    }

    func suspend() {
        suspended = true
        unregister()
    }

    func resume() {
        guard suspended else { return }
        suspended = false
        register(AppSettings.shared.shortcut)
    }

    @objc private func hotKeyPressed() {
        ClipboardPanelController.shared.toggle()
    }

    private func installHandlerIfNeeded() {
        guard handlerRef == nil else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), carbonHotKeyHandler, 1, &spec, nil, &handlerRef)
    }

    private func register(_ shortcut: Shortcut) {
        unregister()
        guard !suspended else { return }

        switch shortcut.kind {
        case .key:
            let id = EventHotKeyID(signature: OSType(0x43505354), id: 1)
            RegisterEventHotKey(shortcut.keyCode, shortcut.carbonModifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
        case .mouse:
            globalMouse = NSEvent.addGlobalMonitorForEvents(matching: .otherMouseDown) { [weak self] event in
                self?.handleMouse(event)
            }
            localMouse = NSEvent.addLocalMonitorForEvents(matching: .otherMouseDown) { [weak self] event in
                self?.handleMouse(event)
                return event
            }
        }
    }

    private func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let monitor = globalMouse { NSEvent.removeMonitor(monitor) }
        if let monitor = localMouse { NSEvent.removeMonitor(monitor) }
        globalMouse = nil
        localMouse = nil
    }

    private func handleMouse(_ event: NSEvent) {
        let shortcut = AppSettings.shared.shortcut
        guard shortcut.kind == .mouse, event.buttonNumber == shortcut.mouseButton else { return }
        let flags = event.modifierFlags.intersection(Shortcut.allowedMask)
        guard flags == shortcut.modifiers else { return }
        DispatchQueue.main.async {
            ClipboardPanelController.shared.toggle()
        }
    }
}
