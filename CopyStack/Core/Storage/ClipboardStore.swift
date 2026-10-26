import Foundation

nonisolated enum ClipboardStore {
    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("CopyStack", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var imagesDirectory: URL {
        let dir = directory.appendingPathComponent("Images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var historyURL: URL {
        directory.appendingPathComponent("history.json")
    }

    static func imageURL(_ name: String) -> URL {
        imagesDirectory.appendingPathComponent(name)
    }

    static func writeImage(_ data: Data, name: String) -> Bool {
        do {
            try data.write(to: imageURL(name), options: .atomic)
            return true
        } catch {
            return false
        }
    }

    static func readImage(name: String) -> Data? {
        try? Data(contentsOf: imageURL(name))
    }

    static func deleteImages(named names: [String]) {
        guard !names.isEmpty else { return }
        for name in names {
            try? FileManager.default.removeItem(at: imageURL(name))
        }
    }

    static func loadHistory() -> [ClipboardItem] {
        guard let data = try? Data(contentsOf: historyURL) else { return [] }
        return (try? JSONDecoder().decode([ClipboardItem].self, from: data)) ?? []
    }

    static func saveHistory(_ items: [ClipboardItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: historyURL, options: .atomic)
    }

    static func deleteHistoryFile() {
        try? FileManager.default.removeItem(at: historyURL)
    }

    static func wipe() {
        deleteHistoryFile()
        try? FileManager.default.removeItem(at: imagesDirectory)
    }

    static func sweepOrphans(keeping names: Set<String>) {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: imagesDirectory.path) else { return }
        for file in files where !names.contains(file) {
            try? FileManager.default.removeItem(at: imageURL(file))
        }
    }

    static func imagesDiskUsage() -> Int {
        guard let files = try? FileManager.default.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        return files.reduce(0) { total, url in
            total + ((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
    }
}
