import AppKit
import Carbon.HIToolbox

nonisolated struct Shortcut: Codable, Equatable, Hashable {
    enum Kind: String, Codable {
        case key
        case mouse
    }

    var kind: Kind
    var keyCode: UInt32 = 0
    var keyLabel: String = ""
    var mouseButton: Int = 2
    var modifierBits: UInt = 0

    static let allowedMask: NSEvent.ModifierFlags = [.command, .shift, .option, .control]

    static let standard = Shortcut(kind: .key, keyCode: 9, keyLabel: "V", mouseButton: 2, modifierBits: NSEvent.ModifierFlags([.command, .shift]).rawValue)

    static let presets: [Shortcut] = [
        standard,
        Shortcut(kind: .key, keyCode: 9, keyLabel: "V", mouseButton: 2, modifierBits: NSEvent.ModifierFlags([.command, .option]).rawValue),
        Shortcut(kind: .key, keyCode: 9, keyLabel: "V", mouseButton: 2, modifierBits: NSEvent.ModifierFlags([.control, .command]).rawValue),
        Shortcut(kind: .mouse, keyCode: 0, keyLabel: "", mouseButton: 2, modifierBits: NSEvent.ModifierFlags([.option]).rawValue),
        Shortcut(kind: .mouse, keyCode: 0, keyLabel: "", mouseButton: 3, modifierBits: 0)
    ]

    static let functionKeyCodes: Set<UInt32> = [122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111, 105, 107, 113, 106]

    static let specialKeyNames: [UInt32: String] = [
        36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋", 76: "⌅", 117: "⌦",
        115: "↖", 119: "↘", 116: "⇞", 121: "⇟",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
        101: "F9", 109: "F10", 103: "F11", 111: "F12", 105: "F13", 107: "F14", 113: "F15", 106: "F16"
    ]

    var modifiers: NSEvent.ModifierFlags {
        get { NSEvent.ModifierFlags(rawValue: modifierBits).intersection(Shortcut.allowedMask) }
        set { modifierBits = newValue.intersection(Shortcut.allowedMask).rawValue }
    }

    var carbonModifiers: UInt32 {
        var result: UInt32 = 0
        if modifiers.contains(.command) { result |= UInt32(cmdKey) }
        if modifiers.contains(.shift) { result |= UInt32(shiftKey) }
        if modifiers.contains(.option) { result |= UInt32(optionKey) }
        if modifiers.contains(.control) { result |= UInt32(controlKey) }
        return result
    }

    static func modifierSymbols(_ flags: NSEvent.ModifierFlags) -> [String] {
        var symbols: [String] = []
        if flags.contains(.control) { symbols.append("⌃") }
        if flags.contains(.option) { symbols.append("⌥") }
        if flags.contains(.shift) { symbols.append("⇧") }
        if flags.contains(.command) { symbols.append("⌘") }
        return symbols
    }

    static func label(for event: NSEvent) -> String {
        if let special = specialKeyNames[UInt32(event.keyCode)] { return special }
        return (event.charactersIgnoringModifiers ?? "?").uppercased()
    }

    var mouseName: String {
        mouseButton == 2 ? "Middle Click" : "Mouse Button \(mouseButton + 1)"
    }

    var parts: [String] {
        let tail = kind == .key ? (keyLabel.isEmpty ? "Key \(keyCode)" : keyLabel) : mouseName
        return Shortcut.modifierSymbols(modifiers) + [tail]
    }

    var display: String {
        parts.joined()
    }

    var menuKeyEquivalent: String? {
        guard kind == .key, keyLabel.count == 1, keyLabel.unicodeScalars.allSatisfy({ $0.isASCII }) else { return nil }
        return keyLabel.lowercased()
    }

    var warning: String? {
        if kind == .mouse && modifiers.isEmpty {
            return "Without a modifier, this click also reaches the app underneath."
        }
        guard kind == .key else { return nil }
        if modifiers == [.command] && ["C", "V", "X", "A", "Z", "Q", "W", "S", "P", "N", "T", "H", "M", "F"].contains(keyLabel) {
            return "This is a standard system shortcut and will be hard to use."
        }
        if modifiers.contains(.command) && (keyCode == 49 || keyCode == 48) && modifiers.count == 1 {
            return "This is reserved by macOS."
        }
        return nil
    }
}

extension NSEvent.ModifierFlags {
    nonisolated var count: Int {
        [Self.command, Self.shift, Self.option, Self.control].filter { contains($0) }.count
    }
}
