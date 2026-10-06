import SwiftUI
import AppKit

private enum CategoryStyle {
    static let all = ["All", "Text", "Files", "Images", "Colors", "Links"]

    static func icon(_ category: String) -> String {
        switch category {
        case "Text":   return "text.alignleft"
        case "Files":  return "doc.fill"
        case "Images": return "photo.fill"
        case "Colors": return "paintpalette.fill"
        case "Links":  return "link"
        default:       return "square.stack.fill"
        }
    }

    static func tint(_ category: String) -> Color {
        switch category {
        case "Text":   return Color(red: 0.55, green: 0.65, blue: 1.00)
        case "Files":  return Color(red: 0.35, green: 0.75, blue: 1.00)
        case "Images": return Color(red: 1.00, green: 0.50, blue: 0.70)
        case "Colors": return Color(red: 1.00, green: 0.68, blue: 0.35)
        case "Links":  return Color(red: 0.40, green: 0.88, blue: 0.62)
        default:       return Color(red: 0.70, green: 0.72, blue: 0.80)
        }
    }

    static func badgeTitle(for type: ClipboardItemType) -> String {
        switch type {
        case .text:   return "Text"
        case .number: return "Number"
        case .phone:  return "Phone"
        case .link:   return "Link"
        case .color:  return "Color"
        case .image:  return "Image"
        case .file:   return "File"
        }
    }
}

struct ClipboardPanelBottomView: View {
    @ObservedObject private var vm = PanelViewModel.shared
    @ObservedObject private var manager = ClipboardManager.shared
    @State private var hoveredIndex: Int? = nil
    @Namespace private var chipNamespace

    var onClose: () -> Void
    var panelWidth: CGFloat
    var panelHeight: CGFloat
    var position: PanelPosition = .bottom
    var edgePadding: CGFloat = 0

    private var activeCategory: String { vm.selectedCategory }
    private func selectCategory(_ category: String) {
        vm.selectedCategory = category
        vm.selectedIndex = 0
    }

    private let gutter: CGFloat = 20
    private let gap: CGFloat = 12
    private let inner: CGFloat = 14
    private let cardWidth: CGFloat = 190
    private let cardHeight: CGFloat = 190
    private let cardRadius: CGFloat = 18
    private var gridRows: [GridItem] { [GridItem(.fixed(cardHeight), spacing: gap)] }
    private var calculatedGridHeight: CGFloat { cardHeight + 28 }

    init(
        panelWidth: CGFloat = NSScreen.screens.first?.visibleFrame.width ?? 720,
        panelHeight: CGFloat = 340,
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
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .background(Color.black.opacity(0.78))

            LinearGradient(
                colors: [CategoryStyle.tint(activeCategory).opacity(0.14), .clear],
                startPoint: .top, endPoint: .center
            )
            .animation(.easeInOut(duration: 0.35), value: activeCategory)
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                header
                filterBar
                Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
                gridContent
            }
        }
        .frame(width: panelWidth)
        .frame(minHeight: panelHeight, maxHeight: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.28), Color.white.opacity(0.06)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .onAppear { vm.reset() }
    }

    private var header: some View {
        HStack(spacing: gap) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))

                TextField("Search clipboard…", text: $vm.searchText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .textFieldStyle(.plain)
                    .foregroundStyle(Color.white)

                if !vm.searchText.isEmpty {
                    Button { vm.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.white.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )

            HStack(spacing: 6) {
                Image(systemName: CategoryStyle.icon(activeCategory))
                    .font(.system(size: 11, weight: .bold))
                Text("\(vm.filteredItems.count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(CategoryStyle.tint(activeCategory))
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(Capsule().fill(CategoryStyle.tint(activeCategory).opacity(0.14)))
        }
        .padding(.horizontal, gutter)
        .padding(.top, 18)
        .padding(.bottom, gap)
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(CategoryStyle.all, id: \.self) { category in
                filterChip(category)
            }
            Spacer(minLength: 0)
            Text("← → to switch")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.3))
        }
        .padding(.horizontal, gutter)
        .padding(.bottom, gap + 2)
    }

    private func filterChip(_ category: String) -> some View {
        let isActive = activeCategory == category
        let tint = CategoryStyle.tint(category)

        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                selectCategory(category)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: CategoryStyle.icon(category))
                    .font(.system(size: 11, weight: .semibold))
                Text(category)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isActive ? Color.white : Color.white.opacity(0.55))
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background {
                if isActive {
                    Capsule()
                        .fill(tint.opacity(0.28))
                        .overlay(Capsule().strokeBorder(tint.opacity(0.7), lineWidth: 1))
                        .matchedGeometryEffect(id: "activeChip", in: chipNamespace)
                } else {
                    Capsule().fill(Color.white.opacity(0.05))
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var gridContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: gridRows, spacing: gap) {
                    ForEach(Array(vm.filteredItems.enumerated()), id: \.element.id) { index, item in
                        card(for: item, index: index)
                            .id(item.id)
                            .onTapGesture { ClipboardManager.shared.paste(item) }
                    }
                }
                .padding(.horizontal, gutter)
                .padding(.vertical, 14)
            }
            .onChange(of: vm.selectedIndex) { newIndex in
                guard vm.filteredItems.indices.contains(newIndex) else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(vm.filteredItems[newIndex].id, anchor: .center)
                }
            }
            .onChange(of: activeCategory) { _ in
                if let first = vm.filteredItems.first {
                    proxy.scrollTo(first.id, anchor: .leading)
                }
            }
        }
        .frame(height: calculatedGridHeight)
        .overlay {
            if vm.filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: CategoryStyle.icon(activeCategory))
                        .font(.system(size: 22))
                    Text(activeCategory == "All"
                         ? "Nothing here yet — copy something with ⌘C"
                         : "No \(activeCategory.lowercased()) copied yet")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Color.white.opacity(0.35))
            }
        }
    }

    private func card(for item: ClipboardItem, index: Int) -> some View {
        let isSelected = vm.selectedIndex == index
        let isHovered = hoveredIndex == index
        let category = item.type.filterCategory
        let tint = CategoryStyle.tint(category)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: CategoryStyle.icon(category))
                        .font(.system(size: 9, weight: .bold))
                    Text(CategoryStyle.badgeTitle(for: item.type))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                .foregroundStyle(tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(tint.opacity(0.15)))

                Spacer(minLength: 0)

                Text(item.date.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.35))
            }

            content(for: item, isSelected: isSelected)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text(item.sourceApp ?? "Unknown")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.4))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(inner)
        .frame(width: cardWidth, height: cardHeight)
        .background(
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isSelected ? 0.17 : (isHovered ? 0.10 : 0.06)),
                            Color.white.opacity(isSelected ? 0.09 : 0.03)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .strokeBorder(
                    isSelected ? tint.opacity(0.9) : Color.white.opacity(isHovered ? 0.22 : 0.08),
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .scaleEffect(isSelected ? 1.03 : (isHovered ? 1.015 : 1.0))
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
        .onHover { hovering in
            hoveredIndex = hovering ? index : (hoveredIndex == index ? nil : hoveredIndex)
        }
    }

    @ViewBuilder
    private func content(for item: ClipboardItem, isSelected: Bool) -> some View {
        switch item.type {
        case .text, .number, .phone:
            Text(item.preview)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Color.white.opacity(isSelected ? 1 : 0.85))
                .multilineTextAlignment(.leading)
                .lineLimit(7)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        default:
            VStack(spacing: 8) {
                iconView(for: item, size: 86)
                Text(item.type == .link ? (item.linkDomain ?? item.preview) : item.preview)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func iconView(for item: ClipboardItem, size: CGFloat) -> some View {
        let radius: CGFloat = 12
        switch item.type {
        case .color:
            if let text = item.text?.trimmingCharacters(in: .whitespacesAndNewlines),
               let color = NSColor(hexString: text) {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color(nsColor: color))
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    )
            } else {
                placeholderIcon(item, size: size)
            }
        case .image:
            ThumbnailView(item: item, size: size, radius: radius)
        case .file:
            if let url = item.fileURLs?.first {
                if url.isImageFile {
                    ThumbnailView(item: item, size: size, radius: radius)
                } else {
                    Image(nsImage: ThumbnailLoader.shared.fileIcon(for: url))
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                }
            } else {
                placeholderIcon(item, size: size)
            }
        default:
            placeholderIcon(item, size: size)
        }
    }

    private func placeholderIcon(_ item: ClipboardItem, size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white.opacity(0.07))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: item.type.iconName)
                    .font(.system(size: size * 0.38, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.7))
            )
    }
}
