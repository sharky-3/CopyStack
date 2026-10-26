import SwiftUI
import AppKit

struct QuickPreviewView: View {
    let item: ClipboardItem

    private var tint: Color { CategoryStyle.tint(item.type.filterCategory) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                HStack(spacing: 5) {
                    Image(systemName: CategoryStyle.icon(item.type.filterCategory))
                        .font(.system(size: 10, weight: .bold))
                    Text(item.type.badgeTitle)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.secondary)

                Text(item.sourceApp ?? "Unknown")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.55))

                Spacer()

                Text(item.statsLabel)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.5))

                Keycap(text: "space")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Rectangle().fill(.primary.opacity(0.08)).frame(height: 1)

            preview
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(.primary.opacity(0.18), lineWidth: 1))
        .padding(16)
    }

    @ViewBuilder
    private var preview: some View {
        switch item.type {
        case .image:
            FillThumbnail(item: item, maxPixel: 1800, fit: true)
                .padding(16)
        case .file:
            fileList
        case .color:
            colorPreview
        case .link:
            linkPreview
        default:
            textPreview
        }
    }

    private var textPreview: some View {
        ScrollView {
            Text(String((item.text ?? "").prefix(30_000)))
                .font(item.isCode ? .system(size: 12.5, design: .monospaced) : .system(size: 14.5, design: .rounded))
                .foregroundStyle(.primary.opacity(0.92))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
        }
    }

    private var linkPreview: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.primary)
            Text(item.linkDomain ?? "")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(item.text ?? "")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.primary.opacity(0.6))
                .textSelection(.enabled)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
    }

    @ViewBuilder
    private var colorPreview: some View {
        if let text = item.text, let color = NSColor(hexString: text) {
            VStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(nsColor: color))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.primary.opacity(0.25), lineWidth: 1))
                Text("\(text.uppercased())   \(color.rgbLabel)")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
            }
            .padding(20)
        } else {
            textPreview
        }
    }

    private var fileList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(item.fileURLs ?? [], id: \.self) { url in
                    HStack(spacing: 12) {
                        Image(nsImage: ThumbnailLoader.shared.fileIcon(for: url))
                            .resizable()
                            .frame(width: 36, height: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(url.lastPathComponent)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text(url.deletingLastPathComponent().path)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(.primary.opacity(0.45))
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                    }
                }
            }
            .padding(20)
        }
    }
}
