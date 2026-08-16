import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Picker("Appearance", selection: $settings.appearanceMode) {
                ForEach(AppAppearanceMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            Picker("Keyboard shortcut", selection: $settings.keyboardShortcut) {
                ForEach(KeyboardShortcutPreset.allCases) { shortcut in
                    Text(shortcut.symbolicDisplayName).tag(shortcut)
                }
            }

            Toggle(
                "Launch at login",
                isOn: Binding(
                    get: { settings.launchAtLoginEnabled },
                    set: { settings.setLaunchAtLoginEnabled($0) }
                )
            )

            if let launchAtLoginStatusText = settings.launchAtLoginStatusText {
                Text(launchAtLoginStatusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let lastSettingsError = settings.lastSettingsError {
                Text(lastSettingsError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if let lastHotKeyError = settings.lastHotKeyError {
                Text(lastHotKeyError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .padding(24)
        .frame(width: 430)
        .preferredColorScheme(settings.appearanceMode.colorScheme)
    }
}
