import EventKit
import os

private let logger = Logger(subsystem: "com.claude.MeetingReminder", category: "CalendarMonitor")

final class CalendarMonitor {
    private let store = EKEventStore()
    private var shownEventIDs: [String: Date] = [:]

    private struct ReminderWindow {
        let minSeconds: TimeInterval
        let maxSeconds: TimeInterval
        let tag: String
    }

    private let reminderWindows = [
        ReminderWindow(minSeconds: 90, maxSeconds: 150, tag: "2min"),
        ReminderWindow(minSeconds: 0, maxSeconds: 30, tag: "30sec"),
    ]

    func requestAccess(completion: @escaping (Bool) -> Void) {
        let status = EKEventStore.authorizationStatus(for: .event)
        logger.info("Current calendar auth status: \(status.rawValue)")

        switch status {
        case .fullAccess, .authorized:
            logger.info("Already have calendar access, skipping request")
            completion(true)
        case .notDetermined:
            logger.info("Requesting calendar access")
            store.requestFullAccessToEvents { granted, error in
                if let error {
                    logger.error("Calendar access error: \(error.localizedDescription)")
                }
                logger.info("Calendar access granted: \(granted)")
                completion(granted)
            }
        default:
            logger.warning("Calendar access denied or restricted (status: \(status.rawValue))")
            completion(false)
        }
    }

    func eventsToRemind() -> [EKEvent] {
        cleanUpShownEvents()

        let now = Date()
        let fiveMinutesFromNow = now.addingTimeInterval(5 * 60)

        let predicate = store.predicateForEvents(
            withStart: now,
            end: fiveMinutesFromNow,
            calendars: nil
        )

        let events = store.events(matching: predicate)

        var result: [EKEvent] = []

        for window in reminderWindows {
            let matched = events.filter { event in
                let secondsUntilStart = event.startDate.timeIntervalSince(now)
                return secondsUntilStart >= window.minSeconds && secondsUntilStart <= window.maxSeconds
            }

            for event in matched {
                guard let id = event.eventIdentifier else { continue }
                let dedupeKey = "\(id)_\(window.tag)"
                if shownEventIDs[dedupeKey] != nil { continue }
                shownEventIDs[dedupeKey] = now
                result.append(event)
            }
        }

        return result
    }

    func nextUpcomingEvent() -> EKEvent? {
        let now = Date()
        let oneDayFromNow = now.addingTimeInterval(24 * 60 * 60)
        let predicate = store.predicateForEvents(withStart: now, end: oneDayFromNow, calendars: nil)
        let events = store.events(matching: predicate)
        return events.first { $0.startDate >= now }
    }

    private func cleanUpShownEvents() {
        let tenMinutesAgo = Date().addingTimeInterval(-10 * 60)
        shownEventIDs = shownEventIDs.filter { $0.value > tenMinutesAgo }
    }
}
