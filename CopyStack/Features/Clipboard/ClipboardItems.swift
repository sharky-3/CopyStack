import Foundation
import AppKit

nonisolated enum ClipboardItemType: String, Codable {
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

    var badgeTitle: String {
        switch self {
        case .text: return "Text"
        case .number: return "Number"
        case .phone: return "Phone"
        case .link: return "Link"
        case .color: return "Color"
        case .image: return "Image"
        case .file: return "File"
        }
    }
}

nonisolated extension URL {
    var isImageFile: Bool {
        let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "heic", "heif", "tiff", "tif", "bmp", "webp"]
        return imageExtensions.contains(pathExtension.lowercased())
    }
}

nonisolated struct ClipboardItem: Identifiable, Equatable, Codable {
    var id = UUID()
    var type: ClipboardItemType
    var date: Date
    var sourceApp: String?
    var sourceBundleID: String?
    var text: String?
    var preview: String = ""
    var charCount: Int = 0
    var wordCount: Int = 0
    var isCode: Bool = false
    var fileURLs: [URL]?
    var imageFile: String?
    var imageType: String?
    var imageHash: String?
    var pixelWidth: Int = 0
    var pixelHeight: Int = 0
    var byteCount: Int = 0
    var isPinned: Bool = false

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id && lhs.date == rhs.date && lhs.isPinned == rhs.isPinned
    }

    static func makeText(_ string: String, app: String?, bundleID: String?) -> ClipboardItem {
        let type = detectType(for: string)
        let small = string.utf8.count < 200_000
        var item = ClipboardItem(type: type, date: Date(), sourceApp: app, sourceBundleID: bundleID)
        item.text = string
        item.preview = makePreview(string)
        item.charCount = small ? string.count : string.utf16.count
        item.wordCount = small ? string.split(whereSeparator: { $0.isWhitespace }).count : 0
        item.isCode = type == .text && looksLikeCode(string)
        item.byteCount = string.utf8.count
        return item
    }

    static func makeFiles(_ urls: [URL], app: String?, bundleID: String?) -> ClipboardItem {
        var item = ClipboardItem(type: .file, date: Date(), sourceApp: app, sourceBundleID: bundleID)
        item.fileURLs = urls
        return item
    }

    nonisolated static func makePreview(_ string: String) -> String {
        let head = String(string.prefix(1600)).replacingOccurrences(of: "\t", with: "    ")
        return head.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated static func looksLikeCode(_ string: String) -> Bool {
        let sample = string.prefix(600)
        guard sample.contains("\n") else { return false }
        let symbols = sample.filter { "{}();=<>[]$#/\\|&".contains($0) }.count
        let ratio = Double(symbols) / Double(max(sample.count, 1))
        return ratio > 0.07 || (sample.contains("    ") && symbols > 6)
    }

    nonisolated static func detectType(for string: String) -> ClipboardItemType {
        guard string.utf16.count <= 600 else { return .text }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("\n") else { return .text }

        if trimmed.range(of: "^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$", options: .regularExpression) != nil {
            return .color
        }

        if let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(), ["http", "https", "ftp", "mailto"].contains(scheme) {
            return .link
        }

        let urlRegex = "^(https?://)?([a-zA-Z0-9\\-]+\\.)+[a-zA-Z]{2,}(/.*)?$"
        if trimmed.range(of: urlRegex, options: [.regularExpression, .caseInsensitive]) != nil {
            return .link
        }

        let types: NSTextCheckingResult.CheckingType = [.phoneNumber]
        if let detector = try? NSDataDetector(types: types.rawValue) {
            let length = (trimmed as NSString).length
            let range = NSRange(location: 0, length: length)
            if let match = detector.firstMatch(in: trimmed, options: [], range: range), match.range.length == length {
                return .phone
            }
        }

        if Double(trimmed) != nil {
            return .number
        }

        return .text
    }

    var linkDomain: String? {
        guard type == .link, let text = text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        let urlString = text.lowercased().hasPrefix("http") ? text : "https://\(text)"
        return URL(string: urlString)?.host ?? text
    }

    var fileTitle: String {
        guard let urls = fileURLs, !urls.isEmpty else { return "File" }
        if urls.count == 1 { return urls[0].lastPathComponent }
        return "\(urls[0].lastPathComponent) +\(urls.count - 1)"
    }

    var searchableText: String {
        switch type {
        case .file: return fileURLs?.map { $0.lastPathComponent }.joined(separator: " ") ?? ""
        case .image: return "image photo screenshot"
        default: return text ?? ""
        }
    }

    var statsLabel: String {
        switch type {
        case .image:
            return "\(pixelWidth) × \(pixelHeight)"
        case .file:
            let count = fileURLs?.count ?? 0
            return count == 1 ? "1 file" : "\(count) files"
        case .color, .link:
            return ""
        default:
            if wordCount > 1 { return "\(wordCount.formatted()) words" }
            return "\(charCount.formatted()) chars"
        }
    }
}
