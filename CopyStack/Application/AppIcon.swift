import AppKit

enum AppIcon {
    static var image: NSImage {
        let candidates: [NSImage?] = [
            NSImage(named: "icon"),
            NSImage(named: "Icon"),
            Bundle.main.path(forResource: "icon", ofType: "png").flatMap { NSImage(contentsOfFile: $0) },
            NSImage(named: "AppLogo"),
            NSImage(named: NSImage.applicationIconName),
            NSApplication.shared.applicationIconImage
        ]
        for candidate in candidates {
            if let candidate, candidate.size.width > 0 { return candidate }
        }
        return NSImage(systemSymbolName: "square.on.square", accessibilityDescription: "CopyStack") ?? NSImage()
    }
}
