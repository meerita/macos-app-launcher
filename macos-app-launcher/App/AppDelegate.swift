import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = AppSettings.shared
    private var windowController: LauncherWindowController?
    private var hotKeyManager: HotKeyManager?
    private var settingsWindowController: SettingsWindowController?
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        settings.applyAppearance()

        let usageStore = UsageStore()
        let viewModel = LauncherViewModel(
            catalog: ApplicationCatalog(),
            search: ApplicationSearch(),
            launcher: ApplicationLauncher(),
            usageStore: usageStore
        )
        let windowController = LauncherWindowController(viewModel: viewModel, settings: settings)
        viewModel.dismissLauncher = { [weak windowController] in
            windowController?.hide()
        }
        let settingsWindowController = SettingsWindowController(settings: settings)

        self.windowController = windowController
        self.settingsWindowController = settingsWindowController
        self.hotKeyManager = HotKeyManager(shortcut: settings.keyboardShortcut) {
            windowController.toggle()
        } onRegistrationFailure: { [weak settings] shortcut, status in
            settings?.reportHotKeyRegistrationFailure(shortcut: shortcut, status: status)
        }
        self.statusBarController = StatusBarController(
            settings: settings,
            onToggleLauncher: { [weak windowController] in
                windowController?.toggle()
            },
            onShowSettings: { [weak settingsWindowController] in
                settingsWindowController?.show()
            }
        )
        settings.onKeyboardShortcutChanged = { [weak hotKeyManager, weak settings] shortcut in
            settings?.clearHotKeyRegistrationFailure()
            hotKeyManager?.updateShortcut(shortcut)
        }

        hotKeyManager?.start()

        Task {
            await viewModel.refreshCatalog()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        windowController?.show()
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager?.stop()
    }
}
