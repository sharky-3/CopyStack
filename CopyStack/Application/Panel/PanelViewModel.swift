import Combine
import Foundation

final class PanelViewModel: ObservableObject {
    static let shared = PanelViewModel()

    @Published var searchText: String = ""
    @Published var selectedCategory: String = "All"
    @Published var selectedIndex: Int = 0

    let categories = ["All", "Text", "Links", "Colors", "Images", "Files"]

    var filteredItems: [ClipboardItem] {
        let all = ClipboardManager.shared.items
        let byCategory = selectedCategory == "All"
            ? all
        : all.filter { $0.type.filterCategory == selectedCategory }
        guard !searchText.isEmpty else { return byCategory }
        return byCategory.filter { $0.searchableText.localizedCaseInsensitiveContains(searchText) }
    }

    func reset() {
        searchText = ""
        selectedCategory = "All"
        selectedIndex = 0
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
        guard filteredItems.indices.contains(selectedIndex) else { return }
        ClipboardManager.shared.paste(filteredItems[selectedIndex])
    }

    func deleteSelected() {
        guard filteredItems.indices.contains(selectedIndex) else { return }
        ClipboardManager.shared.delete(filteredItems[selectedIndex])
        selectedIndex = max(0, selectedIndex - 1)
    }
}
