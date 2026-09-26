import AppKit

extension NSColor {
    convenience init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        hex.removeAll { $0 == "#" }
        guard hex.count == 3 || hex.count == 6 else { return nil }
        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }
        var rgb: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgb) else { return nil }
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255
        let b = CGFloat(rgb & 0x0000FF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
