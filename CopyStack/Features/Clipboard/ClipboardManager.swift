import AppKit
import Combine

final class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()

    @Published private(set) var items: [ClipboardItem] = []
    @Published private(set) var isMonitoring = true

    var maxItems = 20

    private var lastChangeCount: Int
    private var timer: Timer?
    private(set) var isPasting = false

    private init() {
        lastChangeCount = NSPasteboard.general.changeCount
        startMonitoring()
    }

    func startMonitoring() {
        guard timer == nil else { return }
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }

    private func checkPasteboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        guard !isPasting else { return }

        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName

        if let urls = pb.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
           !urls.isEmpty {
            let item = ClipboardItem(type: .file, date: Date(), sourceApp: sourceApp,
                                      text: nil, imageData: nil, fileURLs: urls)
            insertOrBump(item) { $0.fileURLs == urls }
            return
        }

        if let imageData = pb.data(forType: .png) ?? pb.data(forType: .tiff),
           NSImage(data: imageData) != nil {
            let item = ClipboardItem(type: .image, date: Date(), sourceApp: sourceApp,
                                      text: nil, imageData: imageData, fileURLs: nil)
            insertOrBump(item) { $0.imageData == imageData }
            return
        }

        guard let string = pb.string(forType: .string),
              !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let type = ClipboardItem.detectType(for: string)
        let item = ClipboardItem(type: type, date: Date(), sourceApp: sourceApp,
                                  text: string, imageData: nil, fileURLs: nil)
        insertOrBump(item) { $0.text == string && $0.type != .file && $0.type != .image }
    }

    private func insertOrBump(_ item: ClipboardItem, matching isDuplicate: (ClipboardItem) -> Bool) {
        if let idx = items.firstIndex(where: isDuplicate) {
            let existing = items.remove(at: idx)
            items.insert(existing, at: 0)
            return
        }
        items.insert(item, at: 0)
        if items.count > maxItems {
            items.removeLast(items.count - maxItems)
        }
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
    }

    func clearAll() {
        items.removeAll()
    }

    func paste(_ item: ClipboardItem) {
        isPasting = true

        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.type {
        case .file:
            if let urls = item.fileURLs {
                pb.writeObjects(urls as [NSURL])
            }
        case .image:
            if let data = item.imageData {
                pb.setData(data, forType: .png)
            }
        default:
            if let text = item.text {
                pb.setString(text, forType: .string)
            }
        }
        lastChangeCount = pb.changeCount

        let panelController = ClipboardPanelController.shared
        let targetApp = panelController.previousApp
        panelController.close()
        targetApp?.activate(options: [.activateIgnoringOtherApps])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            PasteHelper.simulatePaste()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.isPasting = false
            }
        }
    }
}
