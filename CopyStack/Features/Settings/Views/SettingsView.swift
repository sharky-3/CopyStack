import SwiftUI

struct SettingsView: View {
    @State private var tab: SettingsTab = .general
    @State private var hovered: SettingsTab?
    @Namespace private var space

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Version \(short)"
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 232)

            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 1)

            ZStack {
                switch tab {
                case .general: GeneralSettingsView()
                case .library: LibrarySettingsView()
                case .panel: PanelSettingsView()
                case .shortcut: ShortcutSettingsView()
                case .history: HistorySettingsView()
                case .privacy: PrivacySettingsView()
                case .about: AboutSettingsView()
                }
            }
            .id(tab)
            .transition(.opacity.combined(with: .offset(y: 8)))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 900, maxWidth: .infinity, minHeight: 640, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .animation(.spring(response: 0.4, dampingFraction: 0.88), value: tab)
        .ignoresSafeArea(.container, edges: .all)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                Image(nsImage: AppIcon.image)
                    .resizable()
                    .frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 0) {
                    Text("CopyStack")
                        .font(.system(size: 14.5, weight: .bold, design: .rounded))
                    Text("Settings")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 48)
            .padding(.bottom, 20)

            ForEach(SettingsTab.allCases) { item in
                Button {
                    tab = item
                } label: {
                    HStack(spacing: 10) {
                        IconSquare(symbol: item.symbol, color: item.color, size: 24)
                        Text(item.title)
                            .font(.system(size: 13.5, weight: tab == item ? .semibold : .medium))
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 36)
                    .background {
                        if tab == item {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.primary.opacity(0.09))
                                .matchedGeometryEffect(id: "sidebarSelection", in: space)
                        } else if hovered == item {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.primary.opacity(0.045))
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .onHover { isHovering in
                    if isHovering {
                        hovered = item
                    } else if hovered == item {
                        hovered = nil
                    }
                }
            }

            Spacer()

            Text(version)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 12)
        .frame(maxHeight: .infinity)
        .background(Color.primary.opacity(0.03))
    }
}
