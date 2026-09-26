import SwiftUI

struct ClipboardPanelView: View {
    @ObservedObject private var vm = PanelViewModel.shared
    @ObservedObject private var manager = ClipboardManager.shared
    var onClose: () -> Void

    var body: some View {
        ZStack {
            VisualEffectBlur()
            LinearGradient(colors: [.purple.opacity(0.55), .blue.opacity(0.55)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .blendMode(.overlay)

            VStack(spacing: 0) {
                header
                Divider().opacity(0.2)
                categoryBar
                Divider().opacity(0.15)
                list
                Divider().opacity(0.2)
                footer
            }
        }
        .frame(width: 720, height: 560)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.15), lineWidth: 1))
        .onAppear { vm.reset() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(.white.opacity(0.7))
            TextField("Type to search...", text: $vm.searchText)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
            Spacer()
            Text("\(vm.filteredItems.count) clips")
                .foregroundStyle(.white.opacity(0.6))
                .font(.callout)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var categoryBar: some View {
        HStack(spacing: 8) {
            ForEach(vm.categories, id: \.self) { category in
                Text(category)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(vm.selectedCategory == category ? .white.opacity(0.9) : .white.opacity(0.08))
                    )
                    .foregroundStyle(vm.selectedCategory == category ? .black : .white.opacity(0.8))
                    .onTapGesture {
                        vm.selectedCategory = category
                        vm.selectedIndex = 0
                    }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                ForEach(Array(vm.filteredItems.enumerated()), id: \.element.id) { index, item in
                    row(for: item, index: index)
                        .onTapGesture {
                            vm.selectedIndex = index
                            ClipboardManager.shared.paste(item)
                        }
                }

                if vm.filteredItems.isEmpty {
                    Text("No clips yet — copy something with ⌘C")
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func row(for item: ClipboardItem, index: Int) -> some View {
        let isSelected = index == vm.selectedIndex
        return HStack(spacing: 12) {
            iconView(for: item)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(item.sourceApp ?? "Unknown") · \(item.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            if index < 9 {
                Text("⌘\(index + 1)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? .white.opacity(0.12) : .clear)
        )
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func iconView(for item: ClipboardItem) -> some View {
        if item.type == .color, let color = NSColor(hexString: item.content) {
            RoundedRectangle(cornerRadius: 7).fill(Color(nsColor: color))
        } else {
            RoundedRectangle(cornerRadius: 7)
                .fill(.white.opacity(0.08))
                .overlay(Image(systemName: item.type.iconName).foregroundStyle(.white.opacity(0.7)))
        }
    }

    private var footer: some View {
        HStack(spacing: 18) {
            hint("↑↓", "Navigate")
            hint("↔", "Category")
            hint("↩", "Paste")
            hint("⌘P", "Pin")
            hint("⌫", "Delete")
            Spacer()
            hint("esc", "Close")
        }
        .font(.caption)
        .foregroundStyle(.white.opacity(0.6))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func hint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(key).padding(.horizontal, 6).padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.1)))
            Text(label)
        }
    }
}
