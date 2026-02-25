# MeetingReminder

Native macOS menu bar app that monitors calendar events via EventKit and shows a full-screen semi-transparent overlay 2 minutes before a meeting starts.

## Project Structure

- `Package.swift` — SPM executable target, macOS 14+, embeds Info.plist via `-sectcreate` linker flags
- `Sources/Resources/Info.plist` — `LSUIElement=true`, calendar usage description
- `Sources/MeetingReminder/main.swift` — App entry point, `.accessory` activation policy
- `Sources/MeetingReminder/AppDelegate.swift` — Menu bar status item, 30s polling timer
- `Sources/MeetingReminder/CalendarMonitor.swift` — EventKit queries, 90-150s reminder window, deduplication
- `Sources/MeetingReminder/OverlayController.swift` — Borderless `.screenSaver`-level windows on all screens
- `Sources/MeetingReminder/OverlayContentView.swift` — Dark overlay UI with NSStackView layout: meeting title, time, location, dismiss button, keyboard hint

## Build & Install

Use `/install` or manually: `swift build`, then copy binary into `~/Applications/MeetingReminder.app/Contents/MacOS/`, codesign with calendar entitlement, load launchd plist.

## Key Details

- **Code signing required**: The binary must be ad-hoc signed with `com.apple.security.personal-information.calendars` entitlement for macOS to show the calendar permission dialog.
- **App bundle required**: A `.app` bundle at `~/Applications/MeetingReminder.app` with a proper `Info.plist` is needed for macOS to persist the calendar permission grant.
- **Bundle ID**: `com.claude.MeetingReminder`
- **launchd plist**: `~/Library/LaunchAgents/com.claude.MeetingReminder.plist` — `RunAtLoad`, `KeepAlive`
- **Logging**: Uses `os.Logger` with subsystem `com.claude.MeetingReminder`, view with: `log show --predicate 'subsystem == "com.claude.MeetingReminder"' --info --last 5m`
- **Dismiss overlay**: Click the Dismiss button (single click), or press ESC/Enter twice, or wait 30s auto-dismiss. Uses `NSEvent.addLocalMonitorForEvents` for key handling and `NSApp.activate(ignoringOtherApps:)` to ensure the overlay receives focus.
- **Calendar permission**: Checks `EKEventStore.authorizationStatus` first and skips `requestFullAccessToEvents` if already `.fullAccess`/`.authorized`. Note: ad-hoc re-signing resets the permission grant (status returns to `.notDetermined`).
