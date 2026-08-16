@preconcurrency import Carbon
import Foundation

@MainActor
final class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var shortcut: KeyboardShortcutPreset
    private let onTrigger: @MainActor () -> Void
    private let onRegistrationFailure: @MainActor (KeyboardShortcutPreset, OSStatus) -> Void

    init(
        shortcut: KeyboardShortcutPreset,
        onTrigger: @escaping @MainActor () -> Void,
        onRegistrationFailure: @escaping @MainActor (KeyboardShortcutPreset, OSStatus) -> Void = { _, _ in }
    ) {
        self.shortcut = shortcut
        self.onTrigger = onTrigger
        self.onRegistrationFailure = onRegistrationFailure
    }

    func updateShortcut(_ shortcut: KeyboardShortcutPreset) {
        self.shortcut = shortcut
        stop()
        start()
    }

    func start() {
        guard hotKeyRef == nil else {
            return
        }

        let eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        ]

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else {
                    return noErr
                }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr, hotKeyID.id == 1 else {
                    return noErr
                }

                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in
                    manager.onTrigger()
                }
                return noErr
            },
            1,
            eventTypes,
            selfPointer,
            &eventHandlerRef
        )

        guard installStatus == noErr else {
            return
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x4D414C48), id: 1)
        let registerStatus = RegisterEventHotKey(
            shortcut.carbonKeyCode,
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus != noErr {
            let failedShortcut = shortcut
            stop()
            onRegistrationFailure(failedShortcut, registerStatus)
        }
    }

    func stop() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }
}
