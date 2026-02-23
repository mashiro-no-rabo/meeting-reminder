import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let calendarMonitor = CalendarMonitor()
    private let overlayController = OverlayController()
    private var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()

        calendarMonitor.requestAccess { [weak self] granted in
            guard granted else {
                print("Calendar access denied")
                return
            }
            DispatchQueue.main.async {
                self?.startPolling()
            }
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Meeting Reminder")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Overlay", action: #selector(showOverlayNow), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func startPolling() {
        checkForUpcomingMeetings()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkForUpcomingMeetings()
        }
    }

    private func checkForUpcomingMeetings() {
        let events = calendarMonitor.eventsToRemind()
        for event in events {
            overlayController.showOverlay(title: event.title, startDate: event.startDate)
        }
    }

    @objc private func showOverlayNow() {
        let next = calendarMonitor.nextUpcomingEvent()
        let title = next?.title ?? "No upcoming meetings"
        let startDate = next?.startDate ?? Date()
        overlayController.showOverlay(title: title, startDate: startDate)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
