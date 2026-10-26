
import SwiftUI
import AppKit

enum PanelPalette {
    static var background: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? NSColor(white: 0.1, alpha: 1) : NSColor(white: 0.975, alpha: 1)
        })
    }
}
