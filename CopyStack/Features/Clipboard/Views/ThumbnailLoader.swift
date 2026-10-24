import SwiftUI
import AppKit
import ImageIO

final class ThumbnailLoader {
    static let shared = ThumbnailLoader()

    private let cache = NSCache<NSString, NSImage>()
    private let iconCache = NSCache<NSString, NSImage>()
    private let appIconCache = NSCache<NSString, NSImage>()
    private var appNames: [String: String] = [:]

    private init() {
        cache.totalCostLimit = 96 * 1024 * 1024
        cache.countLimit = 120
        iconCache.countLimit = 80
        appIconCache.countLimit = 60
    }

    private func key(for item: ClipboardItem, maxPixel: CGFloat) -> NSString {
        "\(item.id.uuidString)-\(Int(maxPixel))" as NSString
    }

    func cachedThumbnail(for item: ClipboardItem, maxPixel: CGFloat) -> NSImage? {
        cache.object(forKey: key(for: item, maxPixel: maxPixel))
    }

    func sourceURL(for item: ClipboardItem) -> URL? {
        if let name = item.imageFile {
            return ClipboardStore.imageURL(name)
        }
        if let url = item.fileURLs?.first, url.isImageFile {
            return url
        }
        return nil
    }

    func load(_ item: ClipboardItem, maxPixel: CGFloat) async -> NSImage? {
        let cacheKey = key(for: item, maxPixel: maxPixel)
        if let hit = cache.object(forKey: cacheKey) { return hit }
        guard let url = sourceURL(for: item) else { return nil }

        let thumb: NSImage? = await Task.detached(priority: .userInitiated) {
            ThumbnailLoader.downsample(url: url, maxPixel: maxPixel)
        }.value

        if let thumb {
            cache.setObject(thumb, forKey: cacheKey, cost: Int(thumb.size.width * thumb.size.height * 4))
        }
        return thumb
    }

    nonisolated static func downsample(url: URL, maxPixel: CGFloat) -> NSImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }

    func fileIcon(for url: URL) -> NSImage {
        let cacheKey = url.path as NSString
        if let hit = iconCache.object(forKey: cacheKey) { return hit }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        iconCache.setObject(icon, forKey: cacheKey)
        return icon
    }

    func appIcon(bundleID: String?) -> NSImage? {
        guard let bundleID, !bundleID.isEmpty else { return nil }
        let cacheKey = bundleID as NSString
        if let hit = appIconCache.object(forKey: cacheKey) { return hit }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        appIconCache.setObject(icon, forKey: cacheKey)
        return icon
    }

    func appName(bundleID: String) -> String {
        if let hit = appNames[bundleID] { return hit }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return bundleID }
        let name = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
        appNames[bundleID] = name
        return name
    }
}

struct FillThumbnail: View {
    let item: ClipboardItem
    let maxPixel: CGFloat
    var fit = false

    @State private var image: NSImage?

    private var displayed: NSImage? {
        image ?? ThumbnailLoader.shared.cachedThumbnail(for: item, maxPixel: maxPixel)
    }

    var body: some View {
        Color.primary.opacity(fit ? 0 : 0.06)
            .overlay {
                if let displayed {
                    Image(nsImage: displayed)
                        .resizable()
                        .interpolation(.medium)
                        .aspectRatio(contentMode: fit ? .fit : .fill)
                        .transition(.opacity)
                } else {
                    ProgressView()
                        .controlSize(.small)
                        .opacity(0.5)
                }
            }
            .clipped()
            .task(id: item.id) {
                if ThumbnailLoader.shared.cachedThumbnail(for: item, maxPixel: maxPixel) != nil { return }
                let loaded = await ThumbnailLoader.shared.load(item, maxPixel: maxPixel)
                withAnimation(.easeOut(duration: 0.18)) { image = loaded }
            }
    }
}
