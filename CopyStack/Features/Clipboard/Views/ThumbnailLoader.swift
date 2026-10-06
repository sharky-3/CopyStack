import SwiftUI
import AppKit
import ImageIO

final class ThumbnailLoader {
    static let shared = ThumbnailLoader()
    static let maxPixel: CGFloat = 200

    private let cache = NSCache<NSString, NSImage>()
    private let iconCache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 60
        iconCache.countLimit = 60
    }

    func cached(for item: ClipboardItem) -> NSImage? {
        cache.object(forKey: item.id.uuidString as NSString)
    }

    func fileIcon(for url: URL) -> NSImage {
        let key = url.path as NSString
        if let hit = iconCache.object(forKey: key) { return hit }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        iconCache.setObject(icon, forKey: key)
        return icon
    }

    func load(_ item: ClipboardItem) async -> NSImage? {
        let key = item.id.uuidString as NSString
        if let hit = cache.object(forKey: key) { return hit }

        let data = item.imageData
        let url = item.fileURLs?.first

        let thumb: NSImage? = await Task.detached(priority: .userInitiated) {
            let source: CGImageSource?
            if let data {
                source = CGImageSourceCreateWithData(data as CFData, nil)
            } else if let url {
                source = CGImageSourceCreateWithURL(url as CFURL, nil)
            } else {
                source = nil
            }
            guard let source else { return nil }

            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: ThumbnailLoader.maxPixel
            ]
            guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
            else { return nil }
            return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
        }.value

        if let thumb { cache.setObject(thumb, forKey: key) }
        return thumb
    }
}

struct ThumbnailView: View {
    let item: ClipboardItem
    let size: CGFloat
    let radius: CGFloat

    @State private var image: NSImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color.white.opacity(0.07))

            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.medium)
                    .scaledToFill()
                    .transition(.opacity)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .task(id: item.id) {
            if let hit = ThumbnailLoader.shared.cached(for: item) {
                image = hit
                return
            }
            let loaded = await ThumbnailLoader.shared.load(item)
            withAnimation(.easeOut(duration: 0.15)) { image = loaded }
        }
    }
}
