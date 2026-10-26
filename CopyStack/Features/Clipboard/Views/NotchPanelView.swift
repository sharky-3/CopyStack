import SwiftUI
import AppKit

struct NotchShape: Shape {
    var topRadius: CGFloat
    var bottomRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topRadius, bottomRadius) }
        set {
            topRadius = newValue.first
            bottomRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let t = min(topRadius, rect.height / 2)
        let b = min(bottomRadius, max(rect.height - t, 0) / 2, max(rect.width / 2 - t, 0))
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.minX + t, y: rect.minY + t), control: CGPoint(x: rect.minX + t, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + t, y: rect.maxY - b))
        p.addQuadCurve(to: CGPoint(x: rect.minX + t + b, y: rect.maxY), control: CGPoint(x: rect.minX + t, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - t - b, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - t, y: rect.maxY - b), control: CGPoint(x: rect.maxX - t, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - t, y: rect.minY + t))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.maxX - t, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

struct NotchPanelView: View {
    @ObservedObject private var vm = PanelViewModel.shared

    private let openTop: CGFloat = 16
    private let openBottom: CGFloat = 32

    var body: some View {
        GeometryReader { geo in
            let width = vm.presented ? geo.size.width : vm.notchWidth + 12
            let height = vm.presented ? geo.size.height : vm.notchInset

            ZStack(alignment: .top) {
                NotchShape(topRadius: vm.presented ? openTop : 6, bottomRadius: vm.presented ? openBottom : 10)
                    .fill(Color.black)
                    .frame(width: width, height: height)
                                .animation(.spring(response: 0.55, dampingFraction: 0.66), value: vm.presented)

                tiles
                    .frame(width: geo.size.width - openTop * 2, height: geo.size.height)
                    .opacity(vm.presented ? 1 : 0)
                    .scaleEffect(vm.presented ? 1 : 0.92, anchor: .top)
                    .animation(vm.presented ? .easeOut(duration: 0.28).delay(0.12) : .easeIn(duration: 0.12), value: vm.presented)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private var tiles: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(Array(vm.filteredItems.enumerated()), id: \.element.id) { entry in
                            NotchTile(item: entry.element, index: entry.offset, isSelected: vm.selectedIndex == entry.offset, presented: vm.presented)
                                .equatable()
                                .id(entry.element.id)
                                .onTapGesture {
                                    vm.selectedIndex = entry.offset
                                    ClipboardManager.shared.paste(entry.element)
                                }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, vm.notchInset + 12)
                    .padding(.bottom, 20)
                }
                .onChange(of: vm.selectedIndex) { _, new in
                    guard vm.filteredItems.indices.contains(new) else { return }
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.9)) {
                        proxy.scrollTo(vm.filteredItems[new].id, anchor: .center)
                    }
                }
            }

            if vm.filteredItems.isEmpty {
                Text("Nothing copied yet")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.top, vm.notchInset)
            }
        }
    }
}

struct NotchTile: View, Equatable {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let presented: Bool

    @State private var hovered = false
    @State private var appeared = false

    static func == (lhs: NotchTile, rhs: NotchTile) -> Bool {
        lhs.item == rhs.item && lhs.isSelected == rhs.isSelected && lhs.presented == rhs.presented && lhs.index == rhs.index
    }

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 20, style: .continuous) }

    var body: some View {
        content
            .padding(12)
            .frame(width: 156, height: 120, alignment: .topLeading)
            .background(shape.fill(Color.white.opacity(isSelected ? 0.17 : (hovered ? 0.12 : 0.075))))
            .overlay(shape.strokeBorder(isSelected ? Color.white.opacity(0.85) : Color.clear, lineWidth: 1.5))
            .clipShape(shape)
            .scaleEffect(isSelected ? 1.04 : 1)
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.78), value: isSelected)
            .onHover { hovered = $0 }
            .contentShape(shape)
            .onAppear { appeared = presented }
            .onChange(of: presented) { _, isPresented in
                if isPresented {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.72).delay(0.14 + Double(min(index, 8)) * 0.035)) {
                        appeared = true
                    }
                } else {
                    appeared = false
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch item.type {
        case .image:
            FillThumbnail(item: item, maxPixel: 320)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(-12)
        case .file:
            fileContent
        case .link:
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(item.linkDomain ?? item.preview)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(item.preview)
                    .font(.system(size: 10.5, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(3)
            }
        case .color:
            colorContent
        default:
            Text(item.preview)
                .font(item.isCode ? .system(size: 10.5, design: .monospaced) : .system(size: 11.5, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(6)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private var fileContent: some View {
        if let url = item.fileURLs?.first {
            if url.isImageFile {
                FillThumbnail(item: item, maxPixel: 320)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(-12)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Image(nsImage: ThumbnailLoader.shared.fileIcon(for: url))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    Text(item.fileTitle)
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
            }
        }
    }

    @ViewBuilder
    private var colorContent: some View {
        if let text = item.text, let color = NSColor(hexString: text) {
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: color))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text(text.uppercased())
                    .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
            }
        }
    }
}
