import SwiftUI
import AppKit

struct ClipboardPanelBottomView: View {
    @ObservedObject private var vm = PanelViewModel.shared
    @ObservedObject private var manager = ClipboardManager.shared
    
    var onClose: () -> Void
    var panelWidth: CGFloat
    var panelHeight: CGFloat
    var position: PanelPosition = .bottom
    var edgePadding: CGFloat = 0
    
    private let rowItemHeight: CGFloat = 180
    private let cardWidth: CGFloat = 180
    private let gridRows = [GridItem(.fixed(180), spacing: 8)]
    private let itemSpacing: CGFloat = 10
    private let calculatedGridHeight: CGFloat = 200
    
    init(
        panelWidth: CGFloat = NSScreen.screens.first?.visibleFrame.width ?? 720,
        panelHeight: CGFloat = 350,
        position: PanelPosition = .bottom,
        edgePadding: CGFloat = 0,
        onClose: @escaping () -> Void
    ) {
        self.panelWidth = panelWidth
        self.panelHeight = panelHeight
        self.position = position
        self.edgePadding = edgePadding
        self.onClose = onClose
    }
    
    var body: some View {
        ZStack {
            VisualEffectBlur()
            VStack(spacing: 0) {
                header
                categoryBar
                Divider().opacity(0.15)
                gridContent
                Divider().opacity(0.15)
                footer
            }
        }
        .frame(width: panelWidth)
        .frame(minHeight: panelHeight, maxHeight: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .onAppear {
            vm.reset()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .revealPop(delay: 0.05)

            TextField("Type to search...", text: $vm.searchText)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .revealSide(delay: 0.08)

            Spacer()

            Text("\(vm.filteredItems.count)")
                .foregroundStyle(.white.opacity(0.5))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(.white.opacity(0.1)))
                .revealPop(delay: 0.15)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var categoryBar: some View {
        HStack(spacing: 8) {
            ForEach(Array(vm.categories.enumerated()), id: \.element) { index, category in
                Text(category)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(
                            vm.selectedCategory == category
                            ? .white.opacity(0.9)
                            : .white.opacity(0.08)
                        )
                    )
                    .foregroundStyle(
                        vm.selectedCategory == category ? .black : .white.opacity(0.8)
                    )
                    .onTapGesture {
                        vm.selectedCategory = category
                        vm.selectedIndex = 0
                    }
                    .revealUp(delay: 0.18 + Double(index) * 0.04)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private var gridContent: some View {
        NativeHorizontalScrollView(
            selectedIndex: vm.selectedIndex,
            itemWidth: cardWidth,
            spacing: itemSpacing
        ) {
            LazyHGrid(rows: gridRows, spacing: itemSpacing) {
                ForEach(Array(vm.filteredItems.enumerated()), id: \.element.id) { index, item in
                    card(for: item, index: index)
                        .onTapGesture {
                            vm.selectedIndex = index
                            ClipboardManager.shared.paste(item)
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .frame(height: calculatedGridHeight)
        .overlay {
            if vm.filteredItems.isEmpty {
                Text("No clips yet — copy something with ⌘C")
                    .font(.system(size: 14, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    private func card(for item: ClipboardItem, index: Int) -> some View {
        let isSelected = index == vm.selectedIndex
        let shouldShowMediaIcon = (item.type == .file || item.type == .image || item.type == .color)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                if shouldShowMediaIcon {
                    iconView(for: item, size: 56)
                }
                Spacer()
                shortcutBadge(index: index, isSelected: isSelected)
            }

            Text(item.preview)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(isSelected ? .black : .white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            Text("\(item.sourceApp ?? "Unknown") · \(item.date.formatted(date: .omitted, time: .shortened))")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(isSelected ? .black.opacity(0.6) : .white.opacity(0.4))
                .lineLimit(1)
        }
        .padding(10)
        .frame(width: cardWidth, height: rowItemHeight)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.white : Color.white.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Color.white : Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: isSelected ? .black.opacity(0.25) : .clear, radius: 8, x: 0, y: 4)
        .onHover { isHovered in
            if isHovered {
                vm.selectedIndex = index
            }
        }
    }

    @ViewBuilder
    private func shortcutBadge(index: Int, isSelected: Bool) -> some View {
        if index < 9 {
            Text("⌘\(index + 1)")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(isSelected ? .black.opacity(0.6) : .white.opacity(0.4))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? .black.opacity(0.1) : .white.opacity(0.1))
                )
        }
    }

    @ViewBuilder
    private func iconView(for item: ClipboardItem, size: CGFloat) -> some View {
        let cornerRadius: CGFloat = size > 30 ? 10 : 6

        switch item.type {
        case .color:
            if let text = item.text, let color = NSColor(hexString: text) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(nsColor: color))
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            } else {
                placeholderIcon(item, size: size)
            }

        case .image:
            if let data = item.imageData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                placeholderIcon(item, size: size)
            }

        case .file:
            if let url = item.fileURLs?.first {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                placeholderIcon(item, size: size)
            }

        default:
            EmptyView()
        }
    }

    private func placeholderIcon(_ item: ClipboardItem, size: CGFloat) -> some View {
        let cornerRadius: CGFloat = size > 30 ? 10 : 6
        return RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.white.opacity(0.1))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: item.type.iconName)
                    .font(.system(size: size * 0.45, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            )
    }

    private var footer: some View {
        HStack(spacing: 16) {
            hint("← → ↑ ↓", "Navigate", delay: 0.5)
            hint("↩", "Paste", delay: 0.58)
            hint("⌘P", "Pin", delay: 0.62)
            hint("⌘⌫", "Delete", delay: 0.66)

            Spacer()

            hint("esc", "Close", delay: 0.70)
        }
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .foregroundStyle(.white.opacity(0.6))
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func hint(_ key: String, _ label: String, delay: Double) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.12))
                )
                .revealPop(delay: delay)

            Text(label)
                .revealUp(delay: delay + 0.025)
        }
    }
}
