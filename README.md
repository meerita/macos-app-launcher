# macos-app-launcher

A minimal native macOS application launcher. Press `Option-Space`, type an installed application name, press `Return`, and the selected application launches.

The app is intentionally narrow. It does not search files, documents, the web, browser history, contacts, calendars, clipboard contents, shell commands, plugins, scripts, AI services, or cloud accounts.

## Requirements

- macOS 26+
- Apple Silicon
- Xcode 26.6 or newer
- Swift 6

## Build

```sh
xcodebuild -project macos-app-launcher.xcodeproj -scheme macos-app-launcher -destination 'platform=macOS,arch=arm64' -derivedDataPath .derivedData build
```

## Test

```sh
xcodebuild -project macos-app-launcher.xcodeproj -scheme macos-app-launcher -destination 'platform=macOS,arch=arm64' -derivedDataPath .derivedData test
```

## Privacy

The application performs application discovery and search locally.

It does not require Full Disk Access.
It does not require Accessibility access.
It does not use analytics or telemetry.
It does not send application or search data over the network.

## Permissions

No entitlements are added. The app scans only standard application locations:

- `/Applications`
- `/System/Applications`
- `~/Applications`
- the application directories returned by `FileManager.urls(for: .applicationDirectory, in:)`

The global shortcut uses the native Carbon `RegisterEventHotKey` API for `Option-Space`, which does not require Accessibility permission.
