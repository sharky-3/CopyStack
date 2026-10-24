import SwiftUI

struct SettingsView: View {
    @State private var tab: SettingsTab = .general
    @Namespace private var space

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 236)

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
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 0) {
                    Text("CopyStack")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text("Settings")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 50)
            .padding(.bottom, 18)

            ForEach(SettingsTab.allCases) { item in
                Button {
                    tab = item
                } label: {
                    HStack(spacing: 11) {
                        IconSquare(symbol: item.symbol, color: item.color, size: 28)
                        Text(item.title)
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background {
                        if tab == item {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.primary.opacity(0.1))
                                .matchedGeometryEffect(id: "sidebarSelection", in: space)
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .background(Color.primary.opacity(0.04))
    }
}
