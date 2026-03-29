import SwiftUI
import AppKit

class RecentDocumentsManager: ObservableObject {
    @Published var recentURLs: [URL] = []

    init() {
        refresh()
    }

    /// Refresh our local list from the system's shared document controller
    func refresh() {
        self.recentURLs = NSDocumentController.shared.recentDocumentURLs
    }

    /// Add a file to the system's "Open Recent" list and refresh the UI
    func addRecent(url: URL) {
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
        refresh()
    }

    /// Clear all recent items
    func clear() {
        NSDocumentController.shared.clearRecentDocuments(nil)
        refresh()
    }
}
