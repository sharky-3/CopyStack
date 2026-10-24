import Combine
import Foundation

final class PanelViewModel: ObservableObject {
    static let shared = PanelViewModel()

    @Published var searchText = ""
    @Published var selectedCategory = "All"
    @Published var selectedIndex = 0
    @Published var presented = false
    @Published var isPreviewing = false
    @Published private(set) var filteredItems: [ClipboardItem] = []
    @Published private(set) var openTick = 0

    let categories = CategoryStyle.all
    let gridColumns = 3

    private var bag = Set<AnyCancellable>()

    private init() {
        Publishers.CombineLatest3(
            ClipboardManager.shared.$items,
            $searchText.removeDuplicates().debounce(for: .milliseconds(90), scheduler: DispatchQueue.main),
            $selectedCategory.removeDuplicates()
        )
        .sink { [weak self] items, query, category in
            self?.apply(items: items, query: query, category: category)
        }
        .store(in: &bag)
    }

    var selectedItem: ClipboardItem? {
        filteredItems.indices.contains(selectedIndex) ? filteredItems[selectedIndex] : nil
    }

    private func apply(items: [ClipboardItem], query: String, category: String) {
        var result = items
        if category != "All" {
            result = result.filter { $0.type.filterCategory == category }
        }
        if !query.isEmpty {
            result = result.filter { $0.searchableText.localizedCaseInsensitiveContains(query) || ($0.sourceApp?.localizedCaseInsensitiveContains(query) ?? false) }
        }
        filteredItems = result
        if result.isEmpty {
            selectedIndex = 0
            isPreviewing = false
        } else if selectedIndex >= result.count {
            selectedIndex = result.count - 1
        }
    }

    func prepareForShow() {
        searchText = ""
        selectedCategory = "All"
        selectedIndex = 0
        isPreviewing = false
        apply(items: ClipboardManager.shared.items, query: "", category: "All")
        openTick += 1
    }

    func moveSelection(by delta: Int) {
        let count = filteredItems.count
        guard count > 0 else { return }
        selectedIndex = max(0, min(count - 1, selectedIndex + delta))
    }

    func cycleCategory(by delta: Int) {
        guard let currentIndex = categories.firstIndex(of: selectedCategory) else { return }
        let newIndex = (currentIndex + delta + categories.count) % categories.count
        selectedCategory = categories[newIndex]
        selectedIndex = 0
    }

    func pasteSelected() {
        guard let item = selectedItem else { return }
        ClipboardManager.shared.paste(item)
    }

    func deleteSelected() {
        guard let item = selectedItem else { return }
        ClipboardManager.shared.delete(item)
    }

    func togglePinSelected() {
        guard let item = selectedItem else { return }
        ClipboardManager.shared.togglePin(item)
    }

    func togglePreview() {
        guard selectedItem != nil else { return }
        isPreviewing.toggle()
    }
}
