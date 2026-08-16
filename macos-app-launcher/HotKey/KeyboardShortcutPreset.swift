@preconcurrency import Carbon
import Foundation

enum KeyboardShortcutPreset: String, CaseIterable, Identifiable {
    case commandSpace
    case optionSpace
    case controlSpace
    case controlOptionSpace
    case commandOptionSpace

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .commandSpace:
            "Command Space"
        case .optionSpace:
            "Option Space"
        case .controlSpace:
            "Control Space"
        case .controlOptionSpace:
            "Control Option Space"
        case .commandOptionSpace:
            "Command Option Space"
        }
    }

    var symbolicDisplayName: String {
        switch self {
        case .commandSpace:
            "⌘ Space"
        case .optionSpace:
            "⌥ Space"
        case .controlSpace:
            "⌃ Space"
        case .controlOptionSpace:
            "⌃⌥ Space"
        case .commandOptionSpace:
            "⌘⌥ Space"
        }
    }

    var carbonKeyCode: UInt32 {
        UInt32(kVK_Space)
    }

    var carbonModifiers: UInt32 {
        switch self {
        case .commandSpace:
            UInt32(cmdKey)
        case .optionSpace:
            UInt32(optionKey)
        case .controlSpace:
            UInt32(controlKey)
        case .controlOptionSpace:
            UInt32(controlKey | optionKey)
        case .commandOptionSpace:
            UInt32(cmdKey | optionKey)
        }
    }
}
