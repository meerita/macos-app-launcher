import AppKit
import SwiftUI

struct SearchFieldView: NSViewRepresentable {
    @Binding var text: String

    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onSubmit: () -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> LauncherTextField {
        let textField = LauncherTextField()
        textField.delegate = context.coordinator
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.font = .systemFont(ofSize: 28, weight: .regular)
        textField.placeholderString = "Search applications"
        textField.lineBreakMode = .byTruncatingTail
        textField.maximumNumberOfLines = 1
        textField.cell?.usesSingleLineMode = true
        textField.cell?.wraps = false
        textField.onMoveUp = onMoveUp
        textField.onMoveDown = onMoveDown
        textField.onSubmit = onSubmit
        textField.onCancel = onCancel
        return textField
    }

    func updateNSView(_ nsView: LauncherTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        nsView.onMoveUp = onMoveUp
        nsView.onMoveDown = onMoveDown
        nsView.onSubmit = onSubmit
        nsView.onCancel = onCancel
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        private let text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else {
                return
            }
            text.wrappedValue = textField.stringValue
        }
    }
}

final class LauncherTextField: NSTextField {
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onSubmit: (() -> Void)?
    var onCancel: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        let commandOrOptionFlags = event.modifierFlags.intersection([.command, .option, .control])
        guard commandOrOptionFlags.isEmpty else {
            super.keyDown(with: event)
            return
        }

        switch event.keyCode {
        case 36, 76:
            onSubmit?()
        case 53:
            onCancel?()
        case 125:
            onMoveDown?()
        case 126:
            onMoveUp?()
        default:
            super.keyDown(with: event)
        }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: 42)
    }
}
