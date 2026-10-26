import SwiftUI
import AppKit

private enum CardFormat {
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    static let bytes: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
}

struct ClipboardCardView: View, Equatable {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let metrics: CardMetrics
    let onPaste: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void
    let onPreview: () -> Void

    @State private var hovered = false

    static func == (lhs: ClipboardCardView, rhs: ClipboardCardView) -> Bool {
        lhs.item == rhs.item && lhs.index == rhs.index && lhs.isSelected == rhs.isSelected && lhs.metrics == rhs.metrics
    }

    private var category: String { item.type.filterCategory }
    private var tint: Color { CategoryStyle.tint(category) }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 22, style: .continuous) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .clipped()
            footer
        }
        .padding(14)
        .frame(minWidth: metrics.width, maxWidth: metrics.width ?? .infinity, minHeight: metrics.height, maxHeight: metrics.height)
        .background(background)
        .overlay(border)
        .clipShape(shape)
        .scaleEffect(isSelected ? 1.02 : (hovered ? 1.008 : 1))
        .animation(.spring(response: 0.3, dampingFraction: 0.78), value: isSelected)
        .animation(.easeOut(duration: 0.14), value: hovered)
        .onHover { hovered = $0 }
        .contentShape(shape)
        .onTapGesture(perform: onPaste)
        .contextMenu {
            Button("Paste", action: onPaste)
            Button("Preview", action: onPreview)
            Button(item.isPinned ? "Unpin" : "Pin", action: onTogglePin)
            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        }
    }

    private var background: some View {
        shape.fill(Color.primary.opacity(isSelected ? 0.09 : (hovered ? 0.075 : 0.055)))
    }

    private var border: some View {
        shape.strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(hovered ? 0.2 : 0.08), lineWidth: isSelected ? 1.5 : 1)
    }

    private var header: some View {
        HStack(spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: CategoryStyle.icon(category))
                    .font(.system(size: 9, weight: .bold))
                Text(item.type.badgeTitle)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.primary)
            }

            if index < 9 && (isSelected || hovered) {
                Text("⌘\(index + 1)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.6))
                    .transition(.opacity)
            } else {
                Text(CardFormat.time.string(from: item.date))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.4))
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 6) {
            if let icon = ThumbnailLoader.shared.appIcon(bundleID: item.sourceBundleID) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 14, height: 14)
            }
            Text(item.sourceApp ?? "Unknown")
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(item.statsLabel)
                .lineLimit(1)
        }
        .font(.system(size: 10, weight: .medium, design: .rounded))
        .foregroundStyle(.primary.opacity(0.42))
    }

    @ViewBuilder
    private var content: some View {
        switch item.type {
        case .text, .number, .phone:
            textContent
        case .link:
            linkContent
        case .color:
            colorContent
        case .image:
            imageContent
        case .file:
            fileContent
        }
    }

    private var textContent: some View {
        Text(item.preview)
            .font(item.isCode ? .system(size: 11.5, weight: .regular, design: .monospaced) : .system(size: 13, weight: .regular, design: .rounded))
            .foregroundStyle(.primary.opacity(isSelected ? 1 : 0.88))
            .lineLimit(metrics.textLines)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .mask {
                if item.charCount > 200 {
                    LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.8), .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom)
                } else {
                    Color.black
                }
            }
    }

    private var isWide: Bool { metrics.width == nil && metrics.height < 200 }

    @ViewBuilder
    private var linkContent: some View {
        if isWide {
            linkRow
        } else {
            linkTall
        }
    }

    private var linkRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(.primary.opacity(0.08))
                Image(systemName: "globe")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.linkDomain ?? item.preview)
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(item.preview)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.55))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private var linkTall: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle().fill(.primary.opacity(0.08))
                Image(systemName: "globe")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .frame(width: 42, height: 42)

            Text(item.linkDomain ?? item.preview)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(item.preview)
                .font(.system(size: 11.5, weight: .regular, design: .rounded))
                .foregroundStyle(.primary.opacity(0.55))
                .lineLimit(max(2, metrics.textLines / 2))
                .multilineTextAlignment(.leading)
        }
    }

    @ViewBuilder
    private var colorContent: some View {
        if isWide, let text = item.text, let color = NSColor(hexString: text) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: color))
                    .frame(width: 60, height: 60)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.primary.opacity(0.25), lineWidth: 1))
                VStack(alignment: .leading, spacing: 3) {
                    Text(text.uppercased())
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.primary)
                    Text(color.rgbLabel)
                        .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(.primary.opacity(0.5))
                        .lineLimit(1)
                }
            }
        } else if let text = item.text, let color = NSColor(hexString: text) {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(nsColor: color))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.primary.opacity(0.25), lineWidth: 1))
                Text(text.uppercased())
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                Text(color.rgbLabel)
                    .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                    .foregroundStyle(.primary.opacity(0.5))
            }
        } else {
            textContent
        }
    }

    private var imageContent: some View {
        FillThumbnail(item: item, maxPixel: metrics.thumbPixel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                Text(CardFormat.bytes.string(fromByteCount: Int64(item.byteCount)))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.45), in: Capsule())
                    .padding(8)
            }
    }

    @ViewBuilder
    private var fileContent: some View {
        if let url = item.fileURLs?.first {
            if url.isImageFile {
                FillThumbnail(item: item, maxPixel: metrics.thumbPixel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(alignment: .bottomLeading) {
                        Text(item.fileTitle)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.45), in: Capsule())
                            .padding(8)
                    }
            } else if isWide {
                HStack(spacing: 12) {
                    Image(nsImage: ThumbnailLoader.shared.fileIcon(for: url))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.fileTitle)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(url.deletingLastPathComponent().path)
                            .font(.system(size: 10.5, weight: .regular, design: .rounded))
                            .foregroundStyle(.primary.opacity(0.45))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Image(nsImage: ThumbnailLoader.shared.fileIcon(for: url))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                    Text(item.fileTitle)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text(url.deletingLastPathComponent().path)
                        .font(.system(size: 10.5, weight: .regular, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.45))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        } else {
            textContent
        }
    }
}
