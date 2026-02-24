---
name: install
description: Build, sign, and install MeetingReminder as a launchd agent
allowed-tools: Bash, Read, Write
---

Build, codesign, install the .app bundle, and load the launchd agent. Run these steps:

1. `swift build` — compile the project
2. Create the app bundle directory structure at `~/Applications/MeetingReminder.app/Contents/MacOS/`
3. Copy the built binary from `.build/arm64-apple-macosx/debug/MeetingReminder` to `~/Applications/MeetingReminder.app/Contents/MacOS/MeetingReminder`
4. Write `~/Applications/MeetingReminder.app/Contents/Info.plist` with bundle ID `com.claude.MeetingReminder`, `LSUIElement=true`, `CFBundleExecutable=MeetingReminder`, and `NSCalendarsFullAccessUsageDescription`
5. Ad-hoc codesign the .app bundle with the calendar entitlement:
   ```
   codesign --force --sign - --entitlements /dev/stdin ~/Applications/MeetingReminder.app <<'EOF'
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>com.apple.security.personal-information.calendars</key>
       <true/>
   </dict>
   </plist>
   EOF
   ```
6. Unload existing launchd agent if loaded: `launchctl unload ~/Library/LaunchAgents/com.claude.MeetingReminder.plist 2>/dev/null`
7. Write `~/Library/LaunchAgents/com.claude.MeetingReminder.plist` with Label `com.claude.MeetingReminder`, ProgramArguments pointing to the binary inside the .app bundle, `RunAtLoad=true`, `KeepAlive=true`, stdout/stderr to `/tmp/MeetingReminder.{stdout,stderr}.log`
8. Load the agent: `launchctl load ~/Library/LaunchAgents/com.claude.MeetingReminder.plist`
9. Verify it's running: `launchctl list | grep MeetingReminder`
