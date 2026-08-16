import AppKit
import Combine

@MainActor
final class StatusBarController: NSObject {
    private let settings: AppSettings
    private let onToggleLauncher: () -> Void
    private let onShowSettings: () -> Void
    private let statusItem: NSStatusItem
    private var cancellables: Set<AnyCancellable> = []

    init(
        settings: AppSettings,
        onToggleLauncher: @escaping () -> Void,
        onShowSettings: @escaping () -> Void
    ) {
        self.settings = settings
        self.onToggleLauncher = onToggleLauncher
        self.onShowSettings = onShowSettings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        super.init()

        configureButton()
        rebuildMenu()

        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
            }
            .store(in: &cancellables)
    }

    private func configureButton() {
        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(
            systemSymbolName: "magnifyingglass",
            accessibilityDescription: "App Launcher"
        )
        button.image?.isTemplate = true
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let openItem = NSMenuItem(
            title: "Open Launcher (\(settings.keyboardShortcut.symbolicDisplayName))",
            action: #selector(openLauncher),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        launchAtLoginItem.state = settings.launchAtLoginEnabled ? .on : .off
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit App Launcher",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func openLauncher() {
        onToggleLauncher()
    }

    @objc private func showSettings() {
        onShowSettings()
    }

    @objc private func toggleLaunchAtLogin() {
        settings.setLaunchAtLoginEnabled(!settings.launchAtLoginEnabled)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
