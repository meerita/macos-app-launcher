import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: LauncherWindowController?
    private var hotKeyManager: HotKeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let usageStore = UsageStore()
        let viewModel = LauncherViewModel(
            catalog: ApplicationCatalog(),
            search: ApplicationSearch(),
            launcher: ApplicationLauncher(),
            usageStore: usageStore
        )
        let windowController = LauncherWindowController(viewModel: viewModel)
        viewModel.dismissLauncher = { [weak windowController] in
            windowController?.hide()
        }

        self.windowController = windowController
        self.hotKeyManager = HotKeyManager {
            windowController.toggle()
        }

        hotKeyManager?.start()

        Task {
            await viewModel.refreshCatalog()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager?.stop()
    }
}
