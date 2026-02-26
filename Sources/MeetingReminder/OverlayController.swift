import AppKit

final class OverlayController {
    private var windows: [NSWindow] = []
    private var dismissTimer: Timer?

    var isShowing: Bool { !windows.isEmpty }

    func showOverlay(title: String, startDate: Date, location: String?) {
        dismissAll()

        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.level = .screenSaver
            window.isOpaque = false
            window.backgroundColor = .clear
            window.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
            window.ignoresMouseEvents = false

            let contentView = OverlayContentView(
                title: title,
                startDate: startDate,
                location: location,
                onDismiss: { [weak self] in
                    self?.dismissAll()
                }
            )
            contentView.frame = screen.frame
            window.contentView = contentView

            window.orderFrontRegardless()
            windows.append(window)
        }

        // Activate the app and make the first window key so it receives keyboard events
        NSApp.activate(ignoringOtherApps: true)
        if let firstWindow = windows.first {
            firstWindow.makeKeyAndOrderFront(nil)
        }

        dismissTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
            self?.dismissAll()
        }
    }

    func dismissAll() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        for window in windows {
            (window.contentView as? OverlayContentView)?.removeKeyMonitor()
            window.orderOut(nil)
        }
        windows.removeAll()
        NSApp.hide(nil)
    }
}
