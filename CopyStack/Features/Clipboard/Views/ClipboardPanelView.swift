import SwiftUI
import AppKit

struct ClipboardPanelView: View {
    @ObservedObject private var vm = PanelViewModel.shared
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var manager = ClipboardManager.shared
    @FocusState private var searchFocused: Bool

    var onClose: () -> Void

    private var position: PanelPosition { settings.panelPosition }
    private var layout: PanelLayout { position.layout }
    private var metrics: CardMetrics { settings.cardSize.metrics(for: layout) }
    private var activeCategory: String { vm.selectedCategory }
    private var tint: Color { CategoryStyle.tint(activeCategory) }
    private var panelShape: RoundedRectangle { RoundedRectangle(cornerRadius: 28, style: .continuous) }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                header
                filterBar
                content
                footer
            }

            if vm.isPreviewing, let item = vm.selectedItem {
                QuickPreviewView(item: item)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(2)
            }
        }
        .clipShape(panelShape)
        .overlay(panelShape.strokeBorder(LinearGradient(colors: [.primary.opacity(0.14), .primary.opacity(0.08)], startPoint: .top, endPoint: .bottom), lineWidth: 1))
        .scaleEffect(vm.presented ? 1 : 0.95, anchor: position.anchor)
        .offset(vm.presented ? .zero : position.hiddenOffset)
        .opacity(vm.presented ? 1 : 0)
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: vm.presented)
        .animation(.spring(response: 0.38, dampingFraction: 0.85), value: vm.isPreviewing)
        .ignoresSafeArea()
        .onAppear { searchFocused = true }
        .onChange(of: vm.openTick) { _, _ in searchFocused = true }
    }

    private var background: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)

                TextField("Search clipboard", text: $vm.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .focused($searchFocused)

                if !vm.searchText.isEmpty {
                    Button {
                        vm.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 42)
            .background(Capsule().fill(.primary.opacity(0.07)))
            .overlay(Capsule().strokeBorder(.primary.opacity(0.08), lineWidth: 1))

            HStack(spacing: 6) {
                Image(systemName: CategoryStyle.icon(activeCategory))
                    .font(.system(size: 11, weight: .bold))
                Text("\(vm.filteredItems.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(Capsule().fill(.primary.opacity(0.07)))

            Button {
                SettingsWindowController.shared.show()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(.primary.opacity(0.07)))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.categories, id: \.self) { category in
                        chip(category)
                    }
                }
            }

            if !manager.isMonitoring {
                HStack(spacing: 5) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 9, weight: .bold))
                    if layout != .column {
                        Text("Paused")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                }
                .foregroundStyle(Color.orange)
                .padding(.horizontal, 10)
                .frame(height: 32)
                .background(Capsule().fill(Color.orange.opacity(0.16)))
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 4)
    }

    private func chip(_ category: String) -> some View {
        let isActive = activeCategory == category
        let showsTitle = isActive || layout != .column

        return Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.8)) {
                vm.selectedCategory = category
                vm.selectedIndex = 0
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: CategoryStyle.icon(category))
                    .font(.system(size: 11, weight: .semibold))
                if showsTitle {
                    Text(category)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(isActive ? Color(nsColor: .windowBackgroundColor) : Color.secondary)
            .padding(.horizontal, showsTitle ? 13 : 11)
            .frame(height: 32)
            .background(Capsule().fill(isActive ? Color.primary : Color.primary.opacity(0.07)))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            switch layout {
            case .strip: stripContent
            case .column: columnContent
            case .grid: gridContent
            }

            if vm.filteredItems.isEmpty {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var indexedItems: [(offset: Int, element: ClipboardItem)] {
        Array(vm.filteredItems.enumerated())
    }

    private func card(_ item: ClipboardItem, _ index: Int) -> some View {
        ClipboardCardView(
            item: item,
            index: index,
            isSelected: vm.selectedIndex == index,
            metrics: metrics,
            onPaste: {
                vm.selectedIndex = index
                ClipboardManager.shared.paste(item)
            },
            onTogglePin: { ClipboardManager.shared.togglePin(item) },
            onDelete: { ClipboardManager.shared.delete(item) },
            onPreview: {
                vm.selectedIndex = index
                vm.isPreviewing = true
            }
        )
        .equatable()
        .id(item.id)
    }

    private func scroll(_ proxy: ScrollViewProxy, to index: Int, anchor: UnitPoint = .center) {
        guard vm.filteredItems.indices.contains(index) else { return }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.9)) {
            proxy.scrollTo(vm.filteredItems[index].id, anchor: anchor)
        }
    }

    private var stripContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(indexedItems, id: \.element.id) { entry in
                        card(entry.element, entry.offset)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .onChange(of: vm.selectedIndex) { _, new in scroll(proxy, to: new) }
            .onChange(of: vm.selectedCategory) { _, _ in scroll(proxy, to: 0, anchor: .leading) }
        }
    }

    private var columnContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(indexedItems, id: \.element.id) { entry in
                        card(entry.element, entry.offset)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .onChange(of: vm.selectedIndex) { _, new in scroll(proxy, to: new) }
            .onChange(of: vm.selectedCategory) { _, _ in scroll(proxy, to: 0, anchor: .top) }
        }
    }

    private var gridContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: vm.gridColumns), spacing: 14) {
                    ForEach(indexedItems, id: \.element.id) { entry in
                        card(entry.element, entry.offset)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            }
            .onChange(of: vm.selectedIndex) { _, new in scroll(proxy, to: new) }
            .onChange(of: vm.selectedCategory) { _, _ in scroll(proxy, to: 0, anchor: .top) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: CategoryStyle.icon(activeCategory))
                .font(.system(size: 30, weight: .light))
            Text(emptyMessage)
                .font(.system(size: 14, weight: .medium, design: .rounded))
        }
        .foregroundStyle(.secondary)
    }

    private var emptyMessage: String {
        if !vm.searchText.isEmpty { return "No matches for “\(vm.searchText)”" }
        if activeCategory == "All" { return "Nothing here yet — copy something with ⌘C" }
        return "No \(activeCategory.lowercased()) copied yet"
    }

    private var hints: [(String, String)] {
        switch layout {
        case .strip:
            return [("←→", "Navigate"), ("↩", "Paste"), ("space", "Preview"), ("⌘P", "Pin"), ("⌘⌫", "Delete"), ("⇥", "Filter"), ("esc", "Close")]
        case .column:
            return [("↑↓", "Navigate"), ("↩", "Paste"), ("space", "Preview"), ("⌘⌫", "Delete"), ("esc", "Close")]
        case .grid:
            return [("←↑↓→", "Navigate"), ("↩", "Paste"), ("space", "Preview"), ("⌘P", "Pin"), ("⌘⌫", "Delete"), ("⇥", "Filter"), ("esc", "Close")]
        }
    }

    private func hintView(_ hint: (String, String)) -> some View {
        HStack(spacing: 5) {
            Keycap(text: hint.0)
            Text(hint.1)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var footer: some View {
        Group {
            if layout == .column {
                LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], alignment: .leading, spacing: 8) {
                    ForEach(hints, id: \.0) { hint in
                        hintView(hint)
                    }
                }
            } else {
                HStack(spacing: 16) {
                    ForEach(hints, id: \.0) { hint in
                        hintView(hint)
                    }
                }
            }
        }
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .foregroundStyle(.secondary)
        .minimumScaleFactor(0.7)
        .padding(.horizontal, 22)
        .padding(.bottom, 16)
        .padding(.top, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
