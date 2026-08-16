import AppKit
import SwiftUI

struct SearchFieldView: NSViewRepresentable {
    @Binding var text: String

    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onSubmit: () -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> SearchFieldContainerView {
        let container = SearchFieldContainerView()
        let textField = container.textField
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
        textField.textColor = .labelColor
        context.coordinator.updateCallbacks(
            onMoveUp: onMoveUp,
            onMoveDown: onMoveDown,
            onSubmit: onSubmit,
            onCancel: onCancel
        )
        return container
    }

    func updateNSView(_ nsView: SearchFieldContainerView, context: Context) {
        if nsView.textField.stringValue != text {
            nsView.textField.stringValue = text
        }
        nsView.textField.textColor = .labelColor
        context.coordinator.updateCallbacks(
            onMoveUp: onMoveUp,
            onMoveDown: onMoveDown,
            onSubmit: onSubmit,
            onCancel: onCancel
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        private let text: Binding<String>
        private var onMoveUp: (() -> Void)?
        private var onMoveDown: (() -> Void)?
        private var onSubmit: (() -> Void)?
        private var onCancel: (() -> Void)?

        init(text: Binding<String>) {
            self.text = text
        }

        func updateCallbacks(
            onMoveUp: @escaping () -> Void,
            onMoveDown: @escaping () -> Void,
            onSubmit: @escaping () -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onMoveUp = onMoveUp
            self.onMoveDown = onMoveDown
            self.onSubmit = onSubmit
            self.onCancel = onCancel
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else {
                return
            }
            text.wrappedValue = textField.stringValue
        }

        func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            let modifierFlags = NSApp.currentEvent?.modifierFlags.intersection([.command, .option, .control]) ?? []
            guard modifierFlags.isEmpty else {
                return false
            }

            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)):
                text.wrappedValue = textView.string
                onSubmit?()
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                onCancel?()
                return true
            case #selector(NSResponder.moveUp(_:)):
                onMoveUp?()
                return true
            case #selector(NSResponder.moveDown(_:)):
                onMoveDown?()
                return true
            default:
                return false
            }
        }
    }
}

final class SearchFieldContainerView: NSView {
    let textField = LauncherTextField()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 42)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}

final class LauncherTextField: NSTextField {
    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: 42)
    }
}
