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

extension URL {
    var isImageFile: Bool {
        let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "heic", "heif", "tiff", "tif", "bmp", "webp"]
        return imageExtensions.contains(pathExtension.lowercased())
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

        if let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(), ["http", "https", "ftp", "mailto"].contains(scheme) {
            return .link
        }

        let urlRegex = "^(https?://)?([a-zA-Z0-9\\-]+\\.)+[a-zA-Z]{2,}(/.*)?$"
        if trimmed.range(of: urlRegex, options: [.regularExpression, .caseInsensitive]) != nil {
            return .link
        }

        let types: NSTextCheckingResult.CheckingType = [.link, .phoneNumber]
        if let detector = try? NSDataDetector(types: types.rawValue) {
            let nsString = trimmed as NSString
            let range = NSRange(location: 0, length: nsString.length)
            
            if let match = detector.firstMatch(in: trimmed, options: [], range: range) {
                if match.resultType == .link {
                    return .link
                }
                if match.resultType == .phoneNumber && match.range.length == nsString.length {
                    return .phone
                }
            }
        }

        if Double(trimmed) != nil {
            return .number
        }

        return .text
    }

    var linkDomain: String? {
        guard type == .link, let text = text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }
        let urlString = text.lowercased().hasPrefix("http") ? text : "https://\(text)"
        return URL(string: urlString)?.host ?? text
    }

    var preview: String {
        switch type {
        case .image:
            return "Photo"
        case .file:
            guard let urls = fileURLs, !urls.isEmpty else { return "File" }
            if urls.count == 1 { return urls[0].lastPathComponent }
            return "\(urls.count) files"
        default:
            guard let text else { return "" }
            return text
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
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
