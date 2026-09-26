import Foundation
import AppKit

enum ClipboardItemType {
    case text, link, color, number, phone, image, file

    var filterCategory: String {
        switch self {
        case .link: return "Links"
        case .color: return "Colors"
        case .image: return "Images"
        case .file: return "Files"
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
        case .image: return "photo"
        case .file: return "doc"
        }
    }
}

struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let type: ClipboardItemType
    let date: Date
    let sourceApp: String?

    var text: String?
    var imageData: Data?
    var fileURLs: [URL]?

    static func detectType(for string: String) -> ClipboardItemType {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.range(of: "^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$",
                          options: .regularExpression) != nil {
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
        switch type {
        case .image:
            return "Image"
        case .file:
            guard let urls = fileURLs, !urls.isEmpty else { return "File" }
            if urls.count == 1 { return urls[0].lastPathComponent }
            return "\(urls.count) files"
        default:
            guard let text else { return "" }
            return text.count > 80 ? String(text.prefix(80)) + "…" : text
        }
    }

    var searchableText: String {
        switch type {
        case .file:
            return fileURLs?.map { $0.lastPathComponent }.joined(separator: " ") ?? ""
        case .image:
            return "image"
        default:
            return text ?? ""
        }
    }
}
