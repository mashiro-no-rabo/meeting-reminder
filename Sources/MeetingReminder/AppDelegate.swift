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
        let showItem = NSMenuItem(title: "Show Next Meeting", action: #selector(showOverlayNow), keyEquivalent: "")
        showItem.tag = 1
        menu.addItem(showItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        menu.delegate = self
        statusItem.menu = menu
    }

    private func startPolling() {
        checkForUpcomingMeetings()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkForUpcomingMeetings()
        }
    }

    private func checkForUpcomingMeetings() {
        let events = calendarMonitor.eventsToRemind()
        guard !overlayController.isShowing else { return }
        for event in events {
            overlayController.showOverlay(title: event.title, startDate: event.startDate, location: event.location, url: event.url, notes: event.notes)
        }
    }

    @objc private func showOverlayNow() {
        let next = calendarMonitor.nextUpcomingEvent()
        let title = next?.title ?? "No upcoming meetings"
        let startDate = next?.startDate ?? Date()
        overlayController.showOverlay(title: title, startDate: startDate, location: next?.location, url: next?.url, notes: next?.notes)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard let showItem = menu.item(withTag: 1) else { return }
        let hasNext = calendarMonitor.nextUpcomingEvent() != nil
        showItem.isEnabled = hasNext
        showItem.title = hasNext ? "Show Next Meeting" : "No More Meetings Today"
    }
}
