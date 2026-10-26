import SwiftUI

enum CategoryStyle {
    static let all = ["All", "Text", "Files", "Images", "Colors", "Links"]

    static func icon(_ category: String) -> String {
        switch category {
        case "Text": return "text.alignleft"
        case "Files": return "doc.fill"
        case "Images": return "photo.fill"
        case "Colors": return "paintpalette.fill"
        case "Links": return "link"
        default: return "square.stack.fill"
        }
    }

    static func tint(_ category: String) -> Color {
        switch category {
        case "Text": return Color(red: 0.45, green: 0.58, blue: 1.00)
        case "Files": return Color(red: 0.30, green: 0.75, blue: 1.00)
        case "Images": return Color(red: 1.00, green: 0.42, blue: 0.66)
        case "Colors": return Color(red: 1.00, green: 0.66, blue: 0.28)
        case "Links": return Color(red: 0.34, green: 0.88, blue: 0.60)
        default: return Color(red: 0.72, green: 0.70, blue: 1.00)
        }
    }
}
