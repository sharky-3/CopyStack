import SwiftUI
import AppKit

struct ClipboardPanelBottomView: View {
    @ObservedObject private var vm = PanelViewModel.shared
    @ObservedObject private var manager = ClipboardManager.shared
    
    @State private var hoveredIndex: Int? = nil
    
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
        panelHeight: CGFloat = 300,
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
                Divider()
                gridContent
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
        .padding(16)
    }

    private var gridContent: some View {
        NativeHorizontalScrollView(
            itemWidth: cardWidth,
            spacing: itemSpacing
        ) {
            LazyHGrid(rows: gridRows, spacing: itemSpacing) {
                ForEach(Array(vm.filteredItems.enumerated()), id: \.element.id) { index, item in
                    card(for: item, index: index)
                        .onTapGesture {
                            ClipboardManager.shared.paste(item)
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .frame(height: calculatedGridHeight)
        .padding(.vertical, 16)
        .overlay {
            if vm.filteredItems.isEmpty {
                Text("No clips yet — copy something with ⌘C")
                    .font(.system(size: 14, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    private func card(for item: ClipboardItem, index: Int) -> some View {
        let shouldShowMediaIcon = (item.type == .file || item.type == .image || item.type == .color || item.type == .link)
        let isHovered = hoveredIndex == index
        
        return VStack(alignment: .center, spacing: 6) {
            
            if shouldShowMediaIcon {
                iconView(for: item, size: 150)
            }
            
            if item.type == .text {
                Text(item.preview)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(9)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                Text(item.preview)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Text("\(item.sourceApp ?? "Unknown") · \(item.date.formatted(date: .omitted, time: .shortened))")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(10)
        .frame(width: cardWidth, height: rowItemHeight, alignment: .center)
        .background(.clear)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            hoveredIndex = hovering ? index : nil
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
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                placeholderIcon(item, size: size)
            }

        case .file:
            if let url = item.fileURLs?.first {
                if url.isImageFile, let nsImage = NSImage(contentsOf: url) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                } else {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                }
            } else {
                placeholderIcon(item, size: size)
            }
        case .link:
            placeholderIcon(item, size: size)

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
}


