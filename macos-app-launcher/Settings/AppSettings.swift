import AppKit
import Combine
import ServiceManagement
import SwiftUI

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .system:
            "System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system:
            nil
        case .light:
            NSAppearance(named: .aqua)
        case .dark:
            NSAppearance(named: .darkAqua)
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var appearanceMode: AppAppearanceMode {
        didSet {
            defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode)
            applyAppearance()
        }
    }

    @Published var keyboardShortcut: KeyboardShortcutPreset {
        didSet {
            defaults.set(keyboardShortcut.rawValue, forKey: Keys.keyboardShortcut)
            onKeyboardShortcutChanged?(keyboardShortcut)
        }
    }

    @Published private(set) var launchAtLoginStatus: SMAppService.Status = .notRegistered
    @Published private(set) var lastSettingsError: String?
    @Published private(set) var lastHotKeyError: String?

    var onKeyboardShortcutChanged: ((KeyboardShortcutPreset) -> Void)?

    private let defaults: UserDefaults

    private enum Keys {
        static let appearanceMode = "settings.appearanceMode"
        static let keyboardShortcut = "settings.keyboardShortcut"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedAppearance = defaults.string(forKey: Keys.appearanceMode)
        self.appearanceMode = storedAppearance.flatMap(AppAppearanceMode.init(rawValue:)) ?? .system

        let storedShortcut = defaults.string(forKey: Keys.keyboardShortcut)
        self.keyboardShortcut = storedShortcut.flatMap(KeyboardShortcutPreset.init(rawValue:)) ?? .commandSpace

        refreshLaunchAtLoginStatus()
        applyAppearance()
    }

    var launchAtLoginEnabled: Bool {
        launchAtLoginStatus == .enabled
    }

    var launchAtLoginStatusText: String? {
        switch launchAtLoginStatus {
        case .requiresApproval:
            "Requires approval in System Settings."
        case .notFound:
            "Login item is not available for this app bundle."
        default:
            nil
        }
    }

    func applyAppearance() {
        NSApp.appearance = appearanceMode.nsAppearance
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginStatus = SMAppService.mainApp.status
    }

    func setLaunchAtLoginEnabled(_ isEnabled: Bool) {
        lastSettingsError = nil

        do {
            if isEnabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status != .notRegistered {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            lastSettingsError = error.localizedDescription
        }

        refreshLaunchAtLoginStatus()
    }

    func reportHotKeyRegistrationFailure(shortcut: KeyboardShortcutPreset, status: OSStatus) {
        lastHotKeyError = "Could not register \(shortcut.symbolicDisplayName). System status: \(status)."
    }

    func clearHotKeyRegistrationFailure() {
        lastHotKeyError = nil
    }
}
