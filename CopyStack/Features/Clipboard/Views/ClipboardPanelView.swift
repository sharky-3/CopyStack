import SwiftUI

struct ClipboardPanelView: View {

    @ObservedObject private var vm = PanelViewModel.shared
    @ObservedObject private var manager = ClipboardManager.shared

    var onClose: () -> Void

    var body: some View {
        ZStack {
            VisualEffectBlur()

            VStack(spacing: 0) {
                header
                categoryBar
                Divider()
                list
                Divider()
                footer
            }
        }
        .frame(width: 720, height: 560)
        .clipShape(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .onAppear {
            vm.reset()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {

            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .light, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .revealPop(delay: 0.05)

            TextField("Type to search...", text: $vm.searchText)
                .font(.system(size: 17, weight: .light, design: .rounded))
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .opacity(0.7)
                .revealSide(delay: 0.08)

            Spacer()

            Text("\(vm.filteredItems.count)")
                .foregroundStyle(.white.opacity(0.6))
                .font(.system(size: 13, weight: .light, design: .rounded))
                .revealPop(delay: 0.15)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var categoryBar: some View {
        HStack(spacing: 8) {

            ForEach(
                Array(vm.categories.enumerated()),
                id: \.element
            ) { index, category in

                Text(category)
                    .font(.system(size: 15, weight: .light, design: .rounded))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .frame(minWidth: 75)
                    .background(
                        Capsule()
                            .fill(
                                vm.selectedCategory == category
                                ? .white.opacity(0.9)
                                : .white.opacity(0.08)
                            )
                    )
                    .foregroundStyle(
                        vm.selectedCategory == category
                        ? .black
                        : .white.opacity(0.8)
                    )
                    .onTapGesture {
                        vm.selectedCategory = category
                        vm.selectedIndex = 0
                    }
                    .revealUp(delay: 0.18 + Double(index) * 0.055)
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
                    .font(.system(size: 15, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 20)
                    .padding(.top, 15)
                    .revealSide(delay: 0.28)

                ForEach(
                    Array(vm.filteredItems.enumerated()),
                    id: \.element.id
                ) { index, item in

                    row(for: item, index: index)
                        .onTapGesture {
                            vm.selectedIndex = index
                            ClipboardManager.shared.paste(item)
                        }
                        .revealUp(
                            delay: 0.32 + min(Double(index) * 0.045, 0.45)
                        )
                }

                if vm.filteredItems.isEmpty {

                    Text("No clips yet — copy something with ⌘C")
                        .font(.system(size: 15, weight: .light, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity)
                        .revealUp(delay: 0.35)
                }
            }
        }
    }

    private func row(
        for item: ClipboardItem,
        index: Int
    ) -> some View {

        let isSelected = index == vm.selectedIndex

        return HStack(spacing: 12) {

            iconView(for: item)
                .frame(width: 28, height: 28)
                .revealPop(
                    delay: 0.35 + min(Double(index) * 0.045, 0.4)
                )

            VStack(alignment: .leading, spacing: 2) {

                Text(item.preview)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .revealUp(
                        delay: 0.36 + min(Double(index) * 0.045, 0.4)
                    )

                Text(
                    "\(item.sourceApp ?? "Unknown") · \(item.date.formatted(date: .omitted, time: .shortened))"
                )
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .revealUp(
                    delay: 0.39 + min(Double(index) * 0.045, 0.4)
                )
            }

            Spacer()

            if index < 9 {
                Text("⌘\(index + 1)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.white.opacity(0.4))
                    .revealPop(
                        delay: 0.42 + min(Double(index) * 0.045, 0.4)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isSelected
                    ? .white.opacity(0.12)
                    : .clear
                )
        )
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func iconView(
        for item: ClipboardItem
    ) -> some View {

        switch item.type {

        case .color:

            if let text = item.text,
               let color = NSColor(hexString: text) {

                RoundedRectangle(cornerRadius: 7)
                    .fill(Color(nsColor: color))

            } else {
                placeholderIcon(item)
            }

        case .image:

            if let data = item.imageData,
               let nsImage = NSImage(data: data) {

                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 7)
                    )

            } else {
                placeholderIcon(item)
            }

        case .file:

            if let url = item.fileURLs?.first {

                Image(
                    nsImage: NSWorkspace.shared.icon(
                        forFile: url.path
                    )
                )
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)

            } else {
                placeholderIcon(item)
            }

        default:
            placeholderIcon(item)
        }
    }

    private func placeholderIcon(
        _ item: ClipboardItem
    ) -> some View {

        RoundedRectangle(cornerRadius: 7)
            .fill(.white.opacity(0.08))
            .overlay(
                Image(systemName: item.type.iconName)
                    .foregroundStyle(.white.opacity(0.7))
            )
    }

    private var footer: some View {
        HStack(spacing: 18) {

            hint("↑↓", "Navigate", delay: 0.5)
            hint("↔", "Category", delay: 0.54)
            hint("↩", "Paste", delay: 0.58)
            hint("⌘P", "Pin", delay: 0.62)
            hint("⌘⌫", "Delete", delay: 0.66)

            Spacer()

            hint("esc", "Close", delay: 0.70)
        }
        .font(
            .system(
                size: 12,
                weight: .light,
                design: .rounded
            )
        )
        .foregroundStyle(.white.opacity(0.6))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func hint(
        _ key: String,
        _ label: String,
        delay: Double
    ) -> some View {

        HStack(spacing: 5) {

            Text(key)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.white.opacity(0.1))
                )
                .revealPop(delay: delay)

            Text(label)
                .revealUp(delay: delay + 0.025)
        }
    }
}
