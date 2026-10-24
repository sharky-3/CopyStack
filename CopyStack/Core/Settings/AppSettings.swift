import AppKit
import Combine

enum ScreenTarget: String, CaseIterable, Identifiable {
    case mouse
    case main

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mouse: return "Screen with cursor"
        case .main: return "Main display"
        }
    }
}

private func readBool(_ key: String, _ fallback: Bool) -> Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? fallback
}

private func readDouble(_ key: String, _ fallback: Double) -> Double {
    UserDefaults.standard.object(forKey: key) as? Double ?? fallback
}

private func readInt(_ key: String, _ fallback: Int) -> Int {
    UserDefaults.standard.object(forKey: key) as? Int ?? fallback
}

enum AppearanceTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var appearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let position = "panelPosition"
        static let cardSize = "cardSize"
        static let margin = "edgeMargin"
        static let screen = "screenTarget"
        static let theme = "appearanceTheme"
        static let closeOnFocusLoss = "closeOnFocusLoss"
        static let shortcut = "openShortcut"
        static let maxItems = "maxItems"
        static let saveHistory = "saveHistory"
        static let maxImageMB = "maxImageMB"
        static let autoPaste = "autoPaste"
        static let sounds = "playSounds"
        static let menuBarCount = "showCountInMenuBar"
        static let ignoreConcealed = "ignoreConcealed"
        static let ignoredApps = "ignoredApps"
    }

    @Published var panelPosition: PanelPosition {
        didSet { defaults.set(panelPosition.rawValue, forKey: Key.position) }
    }

    @Published var cardSize: CardSize {
        didSet { defaults.set(cardSize.rawValue, forKey: Key.cardSize) }
    }

    @Published var theme: AppearanceTheme {
        didSet {
            defaults.set(theme.rawValue, forKey: Key.theme)
            applyTheme()
        }
    }

    @Published var edgeMargin: Double {
        didSet { defaults.set(edgeMargin, forKey: Key.margin) }
    }

    @Published var screenTarget: ScreenTarget {
        didSet { defaults.set(screenTarget.rawValue, forKey: Key.screen) }
    }

    @Published var closeOnFocusLoss: Bool {
        didSet { defaults.set(closeOnFocusLoss, forKey: Key.closeOnFocusLoss) }
    }

    @Published var shortcut: Shortcut {
        didSet {
            if let data = try? JSONEncoder().encode(shortcut) {
                defaults.set(data, forKey: Key.shortcut)
            }
        }
    }

    @Published var maxItems: Int {
        didSet { defaults.set(maxItems, forKey: Key.maxItems) }
    }

    @Published var saveHistory: Bool {
        didSet { defaults.set(saveHistory, forKey: Key.saveHistory) }
    }

    @Published var maxImageMB: Int {
        didSet { defaults.set(maxImageMB, forKey: Key.maxImageMB) }
    }

    @Published var autoPaste: Bool {
        didSet { defaults.set(autoPaste, forKey: Key.autoPaste) }
    }

    @Published var playSounds: Bool {
        didSet { defaults.set(playSounds, forKey: Key.sounds) }
    }

    @Published var showCountInMenuBar: Bool {
        didSet { defaults.set(showCountInMenuBar, forKey: Key.menuBarCount) }
    }

    @Published var ignoreConcealed: Bool {
        didSet { defaults.set(ignoreConcealed, forKey: Key.ignoreConcealed) }
    }

    @Published var ignoredApps: [String] {
        didSet { defaults.set(ignoredApps, forKey: Key.ignoredApps) }
    }

    private init() {
        let store = UserDefaults.standard
        panelPosition = PanelPosition(rawValue: store.string(forKey: Key.position) ?? "") ?? .bottom
        cardSize = CardSize(rawValue: store.string(forKey: Key.cardSize) ?? "") ?? .comfortable
        theme = AppearanceTheme(rawValue: store.string(forKey: Key.theme) ?? "") ?? .system
        edgeMargin = readDouble(Key.margin, 12)
        screenTarget = ScreenTarget(rawValue: store.string(forKey: Key.screen) ?? "") ?? .mouse
        closeOnFocusLoss = readBool(Key.closeOnFocusLoss, true)
        if let data = store.data(forKey: Key.shortcut), let decoded = try? JSONDecoder().decode(Shortcut.self, from: data) {
            shortcut = decoded
        } else {
            shortcut = Shortcut.standard
        }
        maxItems = min(max(readInt(Key.maxItems, 20), 5), 50)
        saveHistory = readBool(Key.saveHistory, true)
        maxImageMB = readInt(Key.maxImageMB, 50)
        autoPaste = readBool(Key.autoPaste, true)
        playSounds = readBool(Key.sounds, false)
        showCountInMenuBar = readBool(Key.menuBarCount, true)
        ignoreConcealed = readBool(Key.ignoreConcealed, true)
        ignoredApps = store.stringArray(forKey: Key.ignoredApps) ?? []
    }

    func applyTheme() {
        NSApplication.shared.appearance = theme.appearance
    }

    func resetToDefaults() {
        theme = .system
        panelPosition = .bottom
        cardSize = .comfortable
        edgeMargin = 12
        screenTarget = .mouse
        closeOnFocusLoss = true
        shortcut = Shortcut.standard
        maxItems = 20
        saveHistory = true
        maxImageMB = 50
        autoPaste = true
        playSounds = false
        showCountInMenuBar = true
        ignoreConcealed = true
        ignoredApps = []
    }
}
