import AppKit
import Foundation

@MainActor
final class LauncherViewModel: ObservableObject {
    @Published var query: String = "" {
        didSet {
            updateResults(resetSelection: true)
        }
    }
    @Published private(set) var results: [SearchResult] = []
    @Published private(set) var selectedResultID: String?
    @Published private(set) var lastLaunchError: String?

    var dismissLauncher: (() -> Void)?

    private let catalog: ApplicationCatalog
    private let search: ApplicationSearch
    private let launcher: ApplicationLauncher
    private let usageStore: UsageStore
    private var applications: [InstalledApplication] = []
    private var iconCache: [String: NSImage] = [:]
    private var lastRefresh: Date?
    private var isRefreshing = false

    init(
        catalog: ApplicationCatalog,
        search: ApplicationSearch,
        launcher: ApplicationLauncher,
        usageStore: UsageStore
    ) {
        self.catalog = catalog
        self.search = search
        self.launcher = launcher
        self.usageStore = usageStore
    }

    func prepareForPresentation() {
        lastLaunchError = nil
        query = ""
        updateResults(resetSelection: true)

        if shouldRefreshCatalog {
            Task {
                await refreshCatalog()
            }
        }
    }

    func refreshCatalog() async {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true
        let discoveredApplications = await catalog.discoverApplications()
        applications = discoveredApplications
        lastRefresh = Date()
        isRefreshing = false
        updateResults(resetSelection: true)
    }

    func selectNextResult() {
        guard !results.isEmpty else {
            selectedResultID = nil
            return
        }

        let currentIndex = selectedIndex ?? 0
        let nextIndex = min(results.count - 1, currentIndex + 1)
        selectedResultID = results[nextIndex].id
    }

    func selectPreviousResult() {
        guard !results.isEmpty else {
            selectedResultID = nil
            return
        }

        let currentIndex = selectedIndex ?? 0
        let previousIndex = max(0, currentIndex - 1)
        selectedResultID = results[previousIndex].id
    }

    func launchSelectedResult() {
        guard let selectedApplication = selectedApplication else {
            return
        }

        usageStore.recordLaunch(of: selectedApplication)
        updateResults(resetSelection: false)
        dismissLauncher?()

        Task {
            do {
                try await launcher.launch(selectedApplication)
            } catch {
                lastLaunchError = "Could not launch \(selectedApplication.name)."
            }
        }
    }

    func icon(for application: InstalledApplication) -> NSImage {
        if let cached = iconCache[application.canonicalPath] {
            return cached
        }

        let icon = NSWorkspace.shared.icon(forFile: application.bundleURL.path)
        icon.size = NSSize(width: 32, height: 32)
        iconCache[application.canonicalPath] = icon
        return icon
    }

    func isSelected(_ result: SearchResult) -> Bool {
        result.id == selectedResultID
    }

    private var selectedIndex: Int? {
        guard let selectedResultID else {
            return nil
        }
        return results.firstIndex { $0.id == selectedResultID }
    }

    private var selectedApplication: InstalledApplication? {
        guard let selectedIndex else {
            return results.first?.application
        }
        return results.indices.contains(selectedIndex) ? results[selectedIndex].application : results.first?.application
    }

    private var shouldRefreshCatalog: Bool {
        guard let lastRefresh else {
            return true
        }
        return Date().timeIntervalSince(lastRefresh) > 300
    }

    private func updateResults(resetSelection: Bool) {
        let previousSelection = selectedResultID
        results = search.results(for: query, in: applications, usage: usageStore.records)

        if resetSelection {
            selectedResultID = results.first?.id
        } else if let previousSelection, results.contains(where: { $0.id == previousSelection }) {
            selectedResultID = previousSelection
        } else {
            selectedResultID = results.first?.id
        }
    }
}
