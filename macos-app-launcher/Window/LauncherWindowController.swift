import AppKit
import Combine
import SwiftUI

@MainActor
final class LauncherWindowController: NSWindowController, NSWindowDelegate {
    private let viewModel: LauncherViewModel
    private var cancellables: Set<AnyCancellable> = []

    init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel

        let panel = LauncherPanel()
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true

        super.init(window: panel)

        panel.delegate = self
        panel.contentView = NSHostingView(rootView: LauncherView(viewModel: viewModel))

        viewModel.$results
            .receive(on: RunLoop.main)
            .sink { [weak self] results in
                self?.resize(forResultCount: results.count)
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func toggle() {
        if window?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard let window else {
            return
        }

        viewModel.prepareForPresentation()
        resize(forResultCount: viewModel.results.count)
        position(on: screenContainingMouse() ?? NSScreen.main)

        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        focusSearchField()
    }

    func hide() {
        window?.orderOut(nil)
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    private func resize(forResultCount resultCount: Int) {
        guard let window else {
            return
        }

        let width: CGFloat = 660
        let visibleRows = max(1, min(resultCount, 8))
        let height = CGFloat(82 + (visibleRows * 56) + 14)
        let currentFrame = window.frame
        let topY = currentFrame.maxY
        let centerX = currentFrame.midX
        let frame = NSRect(
            x: centerX - width / 2,
            y: topY - height,
            width: width,
            height: height
        )
        window.setFrame(frame, display: true, animate: false)
    }

    private func position(on screen: NSScreen?) {
        guard let window, let screen else {
            return
        }

        let visibleFrame = screen.visibleFrame
        let frame = window.frame
        let origin = CGPoint(
            x: visibleFrame.midX - frame.width / 2,
            y: visibleFrame.maxY - frame.height - max(80, visibleFrame.height * 0.18)
        )
        window.setFrameOrigin(origin)
    }

    private func screenContainingMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        }
    }

    private func focusSearchField() {
        guard let window else {
            return
        }

        Task { @MainActor in
            if let searchField = window.contentView?.firstSubview(ofType: LauncherTextField.self) {
                window.makeFirstResponder(searchField)
                searchField.selectText(nil)
            }
        }
    }
}

private final class LauncherPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 660, height: 152),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}

private extension NSView {
    func firstSubview<T: NSView>(ofType type: T.Type) -> T? {
        if let match = self as? T {
            return match
        }

        for subview in subviews {
            if let match = subview.firstSubview(ofType: type) {
                return match
            }
        }

        return nil
    }
}
