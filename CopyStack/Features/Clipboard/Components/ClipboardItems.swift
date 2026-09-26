import Foundation

enum ClipboardItemType {
    case text, link, color, number, phone

    var filterCategory: String {
        switch self {
        case .link: return "Links"
        case .color: return "Colors"
        case .text, .number, .phone: return "Text"
        }
    }

    var iconName: String {
        switch self {
        case .link: return "link"
        case .color: return "paintpalette"
        case .number: return "number"
        case .phone: return "phone"
        case .text: return "text.alignleft"
        }
    }
}

struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let type: ClipboardItemType
    let date: Date
    let sourceApp: String?

    static func detectType(for string: String) -> ClipboardItemType {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.range(of: "^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$", options: .regularExpression) != nil {
            return .color
        }

        let types: NSTextCheckingResult.CheckingType = [.link, .phoneNumber]
        if let detector = try? NSDataDetector(types: types.rawValue) {
            let range = NSRange(trimmed.startIndex..., in: trimmed)
            if let match = detector.firstMatch(in: trimmed, options: [], range: range),
               match.range.length == (trimmed as NSString).length {
                if match.resultType == .link { return .link }
                if match.resultType == .phoneNumber { return .phone }
            }
        }

        if Double(trimmed) != nil {
            return .number
        }

        return .text
    }

    var preview: String {
        content.count > 80 ? String(content.prefix(80)) + "…" : content
    }
}
