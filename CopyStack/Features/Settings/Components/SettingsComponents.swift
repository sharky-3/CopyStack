import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case library
    case panel
    case shortcut
    case history
    case privacy
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .library: return "Library"
        case .panel: return "Panel"
        case .shortcut: return "Shortcut"
        case .history: return "History"
        case .privacy: return "Privacy"
        case .about: return "About"
        }
    }

    var subtitle: String {
        switch self {
        case .general: return "Startup, pasting and menu bar behavior."
        case .library: return "Every clip you have copied, all in one place."
        case .panel: return "Choose where the stack appears and how it looks."
        case .shortcut: return "Open CopyStack with a key combo or a mouse button."
        case .history: return "How much to keep, and for how long."
        case .privacy: return "Keep sensitive copies out of your history."
        case .about: return "Version info and resets."
        }
    }

    var symbol: String {
        switch self {
        case .general: return "gearshape.fill"
        case .library: return "square.grid.2x2.fill"
        case .panel: return "macwindow"
        case .shortcut: return "keyboard.fill"
        case .history: return "clock.arrow.circlepath"
        case .privacy: return "hand.raised.fill"
        case .about: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .general: return Color(red: 0.56, green: 0.58, blue: 0.64)
        case .library: return Color(red: 0.0, green: 0.7, blue: 0.85)
        case .panel: return Color(red: 0.25, green: 0.52, blue: 1.0)
        case .shortcut: return Color(red: 1.0, green: 0.58, blue: 0.2)
        case .history: return Color(red: 0.22, green: 0.78, blue: 0.45)
        case .privacy: return Color(red: 0.62, green: 0.38, blue: 0.95)
        case .about: return Color(red: 0.95, green: 0.35, blue: 0.5)
        }
    }
}

struct IconSquare: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 30

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(.white)
            )
    }
}

struct SettingsCard<Content: View>: View {
    let title: String?
    let content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)
            }

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.primary.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.primary.opacity(0.08), lineWidth: 1))
        }
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(.primary.opacity(0.08))
            .frame(height: 1)
    }
}

struct SettingsRow<Trailing: View>: View {
    let symbol: String?
    let color: Color
    let title: String
    let subtitle: String?
    let trailing: Trailing

    init(symbol: String? = nil, color: Color = .blue, title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.symbol = symbol
        self.color = color
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            if let symbol {
                IconSquare(symbol: symbol, color: color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .medium))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)

            trailing
        }
        .padding(.vertical, 11)
    }
}

struct SettingsPage<Content: View>: View {
    let tab: SettingsTab
    let content: Content

    init(_ tab: SettingsTab, @ViewBuilder content: () -> Content) {
        self.tab = tab
        self.content = content()
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tab.title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text(tab.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 4)

                content
            }
            .padding(.horizontal, 30)
            .padding(.top, 46)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
