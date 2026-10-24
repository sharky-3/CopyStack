import SwiftUI

struct LibrarySettingsView: View {
    @ObservedObject private var manager = ClipboardManager.shared
    @State private var query = ""
    @State private var category = "All"
    @State private var previewItem: ClipboardItem?
    @State private var toast: String?

    private let metrics = CardMetrics(width: nil, height: 200, textLines: 8, thumbPixel: 480)

    private var items: [ClipboardItem] {
        var result = manager.items
        if category != "All" {
            result = result.filter { $0.type.filterCategory == category }
        }
        if !query.isEmpty {
            result = result.filter { $0.searchableText.localizedCaseInsensitiveContains(query) || ($0.sourceApp?.localizedCaseInsensitiveContains(query) ?? false) }
        }
        return result
    }

    var body: some View {
        SettingsPage(.library) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search all clips", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                Text("\(items.count) of \(manager.items.count)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.primary.opacity(0.06)))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CategoryStyle.all, id: \.self) { name in
                        let active = category == name
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                category = name
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: CategoryStyle.icon(name))
                                    .font(.system(size: 11, weight: .semibold))
                                Text(name)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(active ? Color(nsColor: .windowBackgroundColor) : Color.secondary)
                            .padding(.horizontal, 13)
                            .frame(height: 30)
                            .background(Capsule().fill(active ? Color.primary : Color.primary.opacity(0.07)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if items.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 34, weight: .light))
                    Text(manager.items.isEmpty ? "Nothing copied yet" : "No clips match")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190, maximum: 280), spacing: 14)], spacing: 14) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { entry in
                        ClipboardCardView(
                            item: entry.element,
                            index: 99,
                            isSelected: false,
                            metrics: metrics,
                            onPaste: { copy(entry.element) },
                            onTogglePin: { manager.togglePin(entry.element) },
                            onDelete: { manager.delete(entry.element) },
                            onPreview: { previewItem = entry.element }
                        )
                        .equatable()
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(Color.black.opacity(0.8)))
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(item: $previewItem) { item in
            QuickPreviewView(item: item)
            .frame(width: 660, height: 480)
            .onExitCommand { previewItem = nil }
        }
    }

    private func copy(_ item: ClipboardItem) {
        manager.copy(item)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            toast = "Copied to clipboard"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.25)) {
                toast = nil
            }
        }
    }
}
